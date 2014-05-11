require 'riak'

require_relative 'riak_bucket'

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

  def bucket
    self.class.bucket
  end

  def store
    bucket[extract_key] = serialize
  end

  module ClassMethods
    def all
      # slow
      db_client.list_keys(bucket.name).map { |key| find(key) }
    end

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
