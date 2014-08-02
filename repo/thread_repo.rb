require_relative 'riak_repo'

module Chibrary

class ThreadRepo
  include RiakRepo

  attr_reader :thread

  def initialize thread
    @thread = thread
  end

  def indexes
    {
      slug_bin: thread.sym.slug,
      sym_bin:  thread.sym.to_key,
      slug_timestamp_next_bin: "#{thread.sym.slug}_#{thread.date.utc.to_i}",
      # Riak secondary indexes do not support reverse order queries, so this
      # creates an index that ascends in the right order to find the previous
      # thread. If you are debugging this in Nov 2286, I'm sorry. Add a digit.
      slug_timestamp_prev_bin: "#{thread.sym.slug}_#{10_000_000_000 - thread.date.utc.to_i}",
      call_number_bin: thread.call_numbers.map { |cn| Base64.strict_encode64(cn) },
      message_id_bin: thread.message_ids.map { |id| Base64.strict_encode64(id) },
      n_subject_bin: thread.n_subjects.map { |s| Base64.strict_encode64(s) },
    }
  end

  def serialize
    {
      sym: SymRepo.new(thread.sym).serialize,
      containers: SummaryContainerRepo.new(thread.root).serialize,
    }
  end

  def extract_key
    self.build_key thread.call_number
  end

  def next_thread
    np_thread :slug_timestamp_next_bin
  end

  def previous_thread
    np_thread :slug_timestamp_prev_bin
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize h
    h.symbolize_keys!
    Thread.new SymRepo.deserialize(h[:sym]), SummaryContainerRepo.deserialize(h[:containers])
  end

  def self.find call_number
    key = build_key(call_number)
    data = bucket[key]
    deserialize data
  end

  def self.root_for call_number
    keys = bucket.get_index('call_number_bin', Base64.strict_encode64(call_number))
    raise NotFound if keys.empty?
    # If this next line is failing, I've managed to store a Message's Summary
    # in two Threads.
    raise TooManyFound if keys.length > 1
    return keys.first
  end

  def self.find_with_messages call_number
    thread = find call_number
    MessageRepo.find_all(thread.call_numbers).each do |message|
      thread.hydrate message
    end
  end

  def self.threads_by_message_id id
    keys = bucket.get_index('message_id_bin', Base64.strict_encode64(id))
    if block_given?
      keys.each { |cn| yield cn }
    else
      keys.map { |cn| find_with_messages(cn) }
    end
  end

  def self.threads_by_n_subject s
    keys = bucket.get_index('n_subject_bin', Base64.strict_encode64(s))
    if block_given?
      keys.ecah { |cn| yield cn }
    else
      keys.map { |cn| find_with_messages(cn) }
    end
  end

  def self.month sym
    load_multiple_threads bucket.get_index('smy_bin', sym.to_key, max_results: 999_999_999)
  end

  def self.load_multiple_threads keys
    threads = bucket.get_many(keys).map { |k, h| deserialize h }
    threads
  end

  def potential_threads_for message
    # Look up any thread that mentions this message's MessageId (eg. has an
    # empty Container waiting for it) and then, from parent to grandparent,
    # look up any MessageId's referenced.
    message.references.reverse.unshift(message.message_id).each do |message_id|
      @threads.each { |t| ThreadRepo.new(t).store }
      threads_by_message_id(message_id) do |call_number|
        yield find_with_messages(call_number)
      end
    end
    # Look up threads by subject
    find_by_n_subject(message.n_subject).each do |call_number|
      yield find_with_messages(call_number)
    end
  end

  private

  def np_thread index
    from = indexes[index].succ
    to = from.gsub(/./, '~') # asciibetically last
    keys = bucket.get_index(index.to_s, (from..to), max_results: 1)
    return nil if keys.empty?
    find keys.first
  end
end

end # Chibrary
