require_relative 'riak_storage'
require_relative '../../lib/container'

module ContainerStorage
  include RiakStorage

  def self.included(base)
    base.send :extend, RiakStorage::ClassMethods
    base.send :extend, ClassMethods
  end

  attr_reader :container

  def initialize container
    @container = container
  end

  def extract_month_key
    self.class.build_month_key(container.slug, container.date.year, container.date.month)
  end

  def serialize_value
    raise NotImplementedError
  end

  def serialize
    {
      key:      container.key,
      value:    serialize_value,
      children: container.children.map { |c| self.class.new(c).serialize },
    }
  end

  def store
    return if container.empty_tree?
    obj = bucket.new
    obj.key = container.call_number
    obj.data = serialize
    obj.indexes['month_bin'] << extract_month_key
    #container.cache_snippet
  end

  module ClassMethods
    def build_month_key slug, year, month
      "#{slug}/#{year}/%02d" % month
    end

    def deserialize_value h
      raise NotImplementedError
    end

    def container_class
      raise NotImplementedError
    end

    def deserialize h
      container = container_class.new h[:key], deserialize_value(h[:value])
      h[:children].each do |child|
        container.adopt self.deserialize(child)
      end
      container
    end

    def find call_number
      hash = bucket[call_number]
      deserialize(hash)
    end

    def month slug, year, month
      bucket.get_index('month_bin', build_month_key(slug, year, month)).map { |call| find(call) }
    end
  end
end
