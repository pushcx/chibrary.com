require_relative 'riak_storage'
require_relative '../time_sort'

class TimeSortStorage
  include RiakStorage

  attr_reader :time_sort

  def initialize time_sort
    @time_sort = time_sort
  end

  def extract_key
    self.class.build_key time_sort.slug, time_sort.year, time_sort.month
  end

  def to_hash
    # it's an array of hashes, but reusing the name saves me writing a new
    # #store
    time_sort.threads.map { |tl| Hash[ tl.each_pair.to_a ] }
  end

  def self.build_key slug, year, month
    "#{slug}/#{year}/%02d" % month
  end

  def self.find slug, year, month
    key = build_key(slug, year, month)
    array = bucket[key]
    TimeSort.new slug, year, month, array
  end

  def self.previous_link slug, year, month, call_number
    previous_link = find(slug, year, month).previous_link(call_number)
    return previous_link if previous_link

    p = Time.utc(year, month).plus_month(-1)
    return find(slug, p.year, p.month).previous_link(call_number)
  end

  def self.next_link slug, year, month, call_number
    next_link = find(slug, year, month).next_link(call_number)
    return next_link if next_link

    n = Time.utc(year, month).plus_month(1)
    return find(slug, n.year, n.month).next_link(call_number)
  end
end
