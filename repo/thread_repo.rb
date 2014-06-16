require_relative 'riak_repo'

class ThreadRepo
  include RiakRepo

  attr_reader :thread

  def initialize thread
    @thread = thread
  end

  def indexes
    {
      slug_bin: thread.slug,
      sym_bin:  thread.sym,
      call_number_bin: thread.call_numbers.map { |cn| Base64.strict_encode64(cn) },
      message_id_bin: thread.message_ids.map { |id| Base64.strict_encode64(id) },
      n_subject_bin: thread.n_subjects.map { |s| Base64.strict_encode64(s) },
    }
  end

  def serialize obj=container
    {
      key:      container.key,
      value:    SummaryRepo.new(container.value).serialize,
      children: container.children.map { |c| serialize(c) },
    }
  end

  def extract_key
    self.build_key thread.call_number
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize h
    h.deep_symbolize_keys!
    containers = []
    containers << container
    container = SummaryContainer.new h[:key], deserialize_value(h[:value])
    h[:children].each do |child|
      containers << container
      container.adopt deserialize(child)
    end
    Thread.new containers
  end

  def self.find_by_root call_number
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

  # TODO Would anyone call this?
  def self.find_by_any call_number
    find_by_root(root_for(call_number))
  end

  def self.find call_number
    raise NotImplementedError, "Call find_by_root or find_by_any"
  end

  def self.find_with_messages call_number
    thread = find_by_root call_number
    MessageRepo.find_all(thread.call_numbers).each do |message|
      thread.hydrate message
    end
  end

  def self.month sym
    keys = bucket.get_index('smy_bin', sym.to_key)
    threads = bucket.get_many(keys).map { |k, h| deserialize h }
    threads.sort!
    threads
  end
end
