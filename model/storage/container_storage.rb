require_relative 'riak_storage'
require_relative '../../lib/container'

module ContainerStorage
  include RiakStorage

  def self.included(base)
    base.send :extend, ClassMethods
  end

  attr_reader :container

  def initialize container
    @container = container
  end

  def extract_month_key
    self.class.build_month_key(container.slug, container.date.year, container.date.month)
  end

  def value_to_hash
    raise NotImplementedError
  end

  def to_hash
    {
      key:      container.key,
      value:    value_to_hash,
      children: container.children.map { |c| self.class.new(c).to_hash },
    }
  end

  def store
    return if container.empty_tree?
    obj = bucket.new
    obj.key = container.call_number
    obj.data = to_hash
    obj.indexes['month_bin'] << extract_month_key
    #container.cache_snippet
  end

  module ClassMethods
    def build_month_key slug, year, month
      "#{slug}/#{year}/%02d" % month
    end

    def value_from_hash h
      raise NotImplementedError
    end

    def container_class
      raise NotImplementedError
    end

    def from_hash h
      container = container_class.new h[:key], value_from_hash(h[:value])
      h[:children].each do |child|
        container.adopt self.from_hash(child)
      end
      container
    end

    def find call_number
      hash = bucket[call_number]
      from_hash(hash)
    end
  end
end
