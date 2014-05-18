require 'riak'

require_relative 'riak_bucket'

Riak.json_options = { max_nesting: 100 }

class NotFound < ArgumentError ; end

module RiakRepo
  def self.included(base)
    base.send :extend, ClassMethods
  end

  def extract_key
    raise NotImplementedError
  end

  def serialize
    raise NotImplementedError
  end

  def indexes
    {}
  end

  def bucket
    self.class.bucket
  end

  def store
    obj = bucket.new
    obj.key = extract_key
    obj.data = serialize
    indexes.each do |index, values|
      Array(values).each do |value|
        obj.indexes[index.to_s] << value.to_s
      end
    end
    obj.store
  end

  module ClassMethods
    def build_key
      raise NotImplementedError
    end

    def bucket
      name = self.name.split('Repo').first.downcase
      @bucket ||= RiakBucket.new db_client.bucket(name)
    end

    def exists? key
      bucket.exists? key
    end

    def db_client
      $riak_client ||= Riak::Client.new(protocol: "pbc", pb_port: 8087)
    end
  end
end
