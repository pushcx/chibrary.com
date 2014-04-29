require_relative 'riak_storage'
require_relative '../month_count'

class MonthCountStorage
  include RiakStorage

  attr_reader :month_count

  def initialize month_count
    @month_count = month_count
  end

  def extract_key
    self.class.build_key month_count.slug, month_count.year, month_count.month
  end

  def serialize
    {
      thread_count: month_count.thread_count,
      message_count: month_count.message_count,
    }
  end

  def store
    obj = bucket.new
    obj.key = extract_key
    obj.data = serialize
    obj.indexes['slug_bin'] << thread_count.slug
    obj.indexes['sy_bin'] << "#{thread_count.slug}/#{thread_count.year}" % thread_count.month
  end

  def self.build_key slug, year, month
    "#{slug}/#{year}/%02d" % month
  end

  def self.find slug, year, month
    key = build_key(slug, year, month)
    hash = bucket[key]
    MonthCount.new slug, year, month, hash[:thread_count], hash[:message_count]
  rescue NotFound
    MonthCount.new slug, year, month
  end

  def self.years_of_month_counts slug
    bucket.
      get_index('slug_bin', slug).
      map { |call| find(call) }.
      each_with_object( {} ) { |mc, years|
        (years[mc.year] ||= {})[mc.month] = mc
      }
  end

end
