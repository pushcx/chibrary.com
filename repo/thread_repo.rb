require 'base64'

require_relative '../entity/thread'
require_relative 'riak_repo'
require_relative 'message_repo'
require_relative 'summary_container_repo'
require_relative 'sym_repo'

module Chibrary

class ThreadRepo
  POTENTIAL_THREADS_TEMPORALLY = 300
  include RiakRepo

  attr_reader :thread

  def initialize thread
    @thread = thread
  end

  def serialize
    {
      slug: thread.slug,
      containers: SummaryContainerRepo.new(thread.root.summarize).serialize,
    }
  end

  def indexes
    {
      slug_bin: thread.slug.to_s,
      sym_bin:  thread.sym.to_key,
      slug_timestamp_next_bin: self.class.build_timestamp_next_index(thread),
      # Riak secondary indexes do not support reverse order queries, so this
      # creates an index that ascends in the right order to find the previous
      # thread. If you are debugging this in Nov 2286, I'm sorry. Add a digit.
      slug_timestamp_prev_bin: self.class.build_timestamp_prev_index(thread),
      call_number_bin: thread.call_numbers.map { |cn| Base64.strict_encode64(cn) },
      slug_message_id_bin: thread.message_ids.map { |id| "#{thread.slug}_#{Base64.strict_encode64(id)}" },
      slug_n_subject_bin: thread.n_subjects.map { |s| "#{thread.slug}_#{Base64.strict_encode64(s)}" },
    }
  end

  def store
    # better to temporarily have two copies than risk the delete succeeding
    # and super's store failing
    super
    bucket.delete thread.initial_root.call_number if thread.root_changed?
    thread.call_numbers.each do |cn|
      thread_cns = bucket.get_index('call_number_bin', Base64.strict_encode64(cn.to_s))
      if thread_cns.length != 1
        raise RuntimeError, "storing #{thread.call_number} just duplicate-stored #{cn}"
      end
    end
  end

  def extract_key
    self.class.build_key thread.call_number.to_s
  end

  def next_thread
    self.class.np_thread :slug_timestamp_next_bin, self.class.build_timestamp_next_index(thread)
  end

  def previous_thread
    self.class.np_thread :slug_timestamp_prev_bin, self.class.build_timestamp_prev_index(thread)
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.build_timestamp_next_index o
    "#{o.slug}_#{o.date.utc.to_i}"
  end

  def self.build_timestamp_prev_index o
    "#{o.slug}_#{10_000_000_000 - o.date.utc.to_i}"
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

  def self.threads_by_message_id slug, id
    find_all bucket.get_index('slug_message_id_bin', "#{slug}_#{Base64.strict_encode64(id)}")
  end

  def self.threads_by_n_subject slug, s
    find_all bucket.get_index('slug_n_subject_bin', "#{slug}_#{Base64.strict_encode64(s)}")
  end

  def self.next_threads message
    from = build_timestamp_next_index(message)
    find_all np_thread_keys(:slug_timestamp_next_bin, from, POTENTIAL_THREADS_TEMPORALLY)
  end

  def self.previous_threads message
    from = build_timestamp_prev_index(message)
    keys = np_thread_keys(:slug_timestamp_prev_bin, from, POTENTIAL_THREADS_TEMPORALLY)
    find_all keys
  end

  def self.month sym
    find_all bucket.get_index('sym_bin', sym.to_key)
  end

  def self.thread_for message
    potential_threads_for(message) do |thread|
      #if message.n_subject =~ /middleware/i or message.n_subject =~ /Sun's sim/i
      #  puts "potential_threads_for: #{message.call_number}, #{message.from}, #{message.subject}"
      #  puts "  thread #{thread.call_number}, #{thread.n_subject} - conversation_for? #{thread.conversation_for? message}"
      #  require 'pry'; binding.pry
      #end
      return thread if thread.conversation_for? message
    end
    Thread.new message.slug, Container.new(message.message_id, message)
  end

  def self.potential_threads_for message
    #puts "potential_threads_for #{message.call_number}"
    # Look up any thread that mentions this message's MessageId (eg. has an
    # empty Container waiting for it) and then, from parent to grandparent,
    # look up any MessageId's referenced.
    message.references.reverse.unshift(message.message_id).each do |message_id|
      threads_by_message_id(message.slug, message_id) do |thread|
        next if thread.call_number == message.call_number
        #puts "id potential #{thread.call_number}"
        yield thread
      end
    end
    # Look up threads by subject
    threads_by_n_subject(message.slug, message.n_subject).each do |thread|
      next if thread.call_number == message.call_number
      #puts "n_subject potential #{thread.call_number}"
      # need to check quote text when an archive is missing ids
      thread.messagize MessageRepo.find_all(thread.call_numbers)
      yield thread
    end
    # try all earlier threads from the list
    previous_threads(message).each do |thread|
      #puts "previous potential #{thread.call_number}"
      thread.messagize MessageRepo.find_all(thread.call_numbers)
      yield thread
    end
    # Finally, try later messages - if this becomes the root it'll drag the
    # thread forward in time
    next_threads(message).each do |thread|
      #puts "next potential #{thread.call_number}"
      thread.messagize MessageRepo.find_all(thread.call_numbers)
      yield thread
    end
  end

  private

  def self.np_thread index, from
    keys = np_thread_keys index, from, 1
    return nil if keys.empty?
    find keys.first
  end

  def self.np_thread_keys index, from, max_results
    first = from.succ
    last = first.gsub(/./, '~') # asciibetically last
    keys = bucket.get_index(index.to_s, first..last, max_results: max_results)
  end
end

end # Chibrary
