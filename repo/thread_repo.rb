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

  def serialize
    thread
  end

  def extract_key
    self.build_key thread.call_number
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize h
    Thread.new h
  end

  def self.find_by_root_call_number call_number
    key = build_key(call_number)
    data = bucket[key]
    deserialize data
  end

  def self.find_by_any_call_number call_number
    keys = bucket.get_index('call_number_bin', Base64.strict_encode64(call_number))
    raise NotFound if keys.empty?
    # If this next line is failing, I've managed to store a Message's Summary
    # in two Threads.
    raise TooManyFound if keys.length > 1
    find_by_root_call_number(keys.first)
  end

  def self.find call_number
    # common enough it's worth trying to skip the index
    find_by_root_call_number call_number
  rescue NotFound
    find_by_any_call_number call_number
  end

  def self.find_with_messages call_number
    thread = find call_number
    MessageRepo.find_all(thread.call_numbers).each do |message|
      thread.hydrate message
    end
  end

  def self.month sym
  end
end
