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

  # WARN: extract_key and build_key are not generic; they only will work for
  # MessageContainerStorage and SummaryContainerStorage
  def extract_key
    slug = container.slug
    year = container.date.year
    month = container.date.month
    call_number = container.call_number

    "/#{slug}/#{year}/%02d/#{call_number}" % month
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
    bucket[extract_key] = to_hash
    #container.cache_snippet
  end

  module ClassMethods
    def build_key slug, year, month, call_number
      "/#{slug}/#{year}/%02d/#{call_number}" % month
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

    def find slug, year, month, call_number
      key = build_key(slug, year, month, call_number)
      hash = bucket[key]
      from_hash(hash)
    end
  end
end
