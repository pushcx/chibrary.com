require_relative 'riak_repo'
require_relative 'list_address_repo'
require_relative 'summary_container_repo'
require_relative 'sym_repo'

module Chibrary

class ThreadRepo
  include RiakRepo

  attr_reader :thread

  def initialize thread
    @thread = thread
  end

  def serialize
    {
      slug: thread.slug,
      containers: SummaryContainerRepo.new(thread.root).serialize,
    }
  end

  def indexes
    {
      slug_bin: thread.slug.to_s,
      sym_bin:  thread.sym.to_key,
      slug_timestamp_next_bin: "#{thread.slug}_#{thread.date.utc.to_i}",
      # Riak secondary indexes do not support reverse order queries, so this
      # creates an index that ascends in the right order to find the previous
      # thread. If you are debugging this in Nov 2286, I'm sorry. Add a digit.
      slug_timestamp_prev_bin: "#{thread.slug}_#{10_000_000_000 - thread.date.utc.to_i}",
      call_number_bin: thread.call_numbers.map { |cn| Base64.strict_encode64(cn) },
      message_id_bin: thread.message_ids.map { |id| Base64.strict_encode64(id) },
      n_subject_bin: thread.n_subjects.map { |s| Base64.strict_encode64(s) },
    }
  end

  def extract_key
    self.class.build_key thread.root.call_number.to_s
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
    h.deep_symbolize_keys!
    Thread.new h[:slug], SummaryContainerRepo.deserialize(h.fetch(:containers))
  end

  def self.root_for call_number
    keys = bucket.get_index('call_number_bin', Base64.strict_encode64(call_number.to_s))
    raise NotFound if keys.empty?
    # If this next line is failing, I've managed to store a Message's Summary
    # in two Threads.
    raise TooManyFound if keys.length > 1
    return CallNumber.new(keys.first)
  end

  def self.find call_number
    key = build_key(call_number)
    data = bucket[key]
    deserialize data
  end

  def self.find_with_messages call_number
    thread = find call_number
    thread.messagize MessageRepo.find_all(thread.call_numbers)
    thread
  end

  def self.find_all call_numbers
    threads = bucket.get_all(call_numbers).map { |k, h| deserialize h }
    threads.sort!
    threads
  end

  def self.threads_by_message_id id
    find_all bucket.get_index('message_id_bin', Base64.strict_encode64(id))
  end

  def self.threads_by_n_subject s
    find_all bucket.get_index('n_subject_bin', Base64.strict_encode64(s))
  end

  def self.month sym
    find_all bucket.get_index('smy_bin', sym.to_key)
  end

  def self.thread_for message
    potential_threads_for(message) do |thread|
      next unless slugs.include? thread.slug
      return thread if thread.conversation_for? message
    end
    Thread.new slugs.first, [message]
  end

  def self.potential_threads_for message
    # Look up any thread that mentions this message's MessageId (eg. has an
    # empty Container waiting for it) and then, from parent to grandparent,
    # look up any MessageId's referenced.
    message.references.reverse.unshift(message.message_id).each do |message_id|
      threads_by_message_id(message_id) do |call_number|
        thread = find_with_messages(call_number)
        next unless thread.slug == message.slug
        yield thread
      end
    end
    # Look up threads by subject
    threads_by_n_subject(message.n_subject).each do |call_number|
      thread = find_with_messages(call_number)
      next unless thread.slug == message.slug
      yield thread
    end
  end

  private

  def np_thread index
    first = indexes[index].succ
    last = first.gsub(/./, '~') # asciibetically last
    keys = bucket.get_index(index.to_s, first..last, max_results: 1)
    return nil if keys.empty?
    find keys.first
  end
end

end # Chibrary
