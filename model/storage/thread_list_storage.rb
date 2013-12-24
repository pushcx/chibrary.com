require_relative 'riak_storage'
require_relative '../thread_list'

class ThreadListStorage
  include RiakStorage

  attr_reader :thread_list, :slug, :year, :month

  def initialize thread_list, slug, year, month
    @thread_list = thread_list
    @slug = slug
    @year = year
    @month = month
  end

  def extract_key

  end

  def self.build_key

  end

  def to_hash
    {
      threads: thread_list.threads,
      call_numbers: thread_list.call_numbers,
    }
  end

  def store
    return if thread.call_numbers.empty?
  end

  def self.from_hash
  end

  def self.find

  end
end
