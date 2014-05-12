require_relative 'riak_repo'
require_relative '../lib/container'

module ContainerRepo
  include RiakRepo

  def self.included(base)
    base.send :extend, RiakRepo::ClassMethods
    base.send :extend, ClassMethods
  end

  attr_reader :container

  def initialize container
    @container = container
  end

  def extract_month_key
    self.class.build_month_key(Sym.from_container(container))
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
    def build_month_key sym
      sym.to_key
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
      hash = bucket[call_number.to_s]
      # messagecontainer didn't get written, no tree
      deserialize(hash)
    end

    def thread call_number
      # TODO
    end

    def month sym
      bucket.get_index('month_bin', build_month_key(sym)).map { |call| find(call) }
    end
  end
end
