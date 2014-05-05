require_relative 'riak_storage'
require_relative '../sym'
require_relative '../time_sort'
require_relative 'thread_link_storage'

class TimeSortStorage
  include RiakStorage

  attr_reader :time_sort

  def initialize time_sort
    @time_sort = time_sort
  end

  def extract_key
    self.class.build_key time_sort.sym
  end

  def serialize
    time_sort.threads.map { |tl| ThreadLinkStorage.new(tl).serialize }
  end

  def self.build_key sym
    sym.to_key
  end

  def self.find sym
    key = build_key(sym)
    array = bucket[key]
    TimeSort.new sym, array
  end

  def self.previous_link sym, call_number
    previous_link = find(sym).previous_link(call_number)
    return previous_link if previous_link

    find(sym.plus_month(-1)).previous_link(call_number)
  end

  def self.next_link sym, call_number
    next_link = find(sym).next_link(call_number)
    return next_link if next_link

    find(sym.plus_month(1)).next_link(call_number)
  end
end
