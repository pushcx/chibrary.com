require_relative 'riak_repo'
require_relative '../value/month_count'
require_relative 'sym_repo'

module Chibrary

class MonthCountRepo
  include RiakRepo

  attr_reader :month_count

  def initialize month_count
    @month_count = month_count
  end

  def extract_key
    self.class.build_key month_count.sym
  end

  def serialize
    {
      thread_count: month_count.thread_count,
      message_count: month_count.message_count,
    }
  end

  def store
    return if month_count.empty?
    obj = bucket.new
    obj.key = extract_key
    obj.data = serialize
    obj.indexes['slug_bin'] << month_count.sym.slug
    obj.indexes['sy_bin'] << month_count.sym.to_sy.to_key
    obj.store
  end

  def self.build_key sym
    sym.to_key
  end

  def self.deserialize key, hash
    MonthCount.new SymRepo.deserialize(key), hash[:thread_count], hash[:message_count]
  end

  def self.retrieve key
    hash = bucket[key]
    deserialize key, hash
  end

  def self.find sym
    key = build_key(sym)
    retrieve key
  rescue NotFound
    MonthCount.new sym
  end

  def self.years_of_month_counts slug
    keys = bucket. get_index('slug_bin', slug.to_s)
    bucket.get_all(keys).map { |k, h| deserialize k, h }.
      each_with_object( {} ) { |mc, years|
        (years[mc.sym.year] ||= {})[mc.sym.month] = mc
      }
  end

end

end # Chibrary
