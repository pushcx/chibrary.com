require 'riak'

module RiakStorage
  def self.included(base)
    base.send :extend, ClassMethods
  end

  def key
    raise NotImplementedError
  end

  def to_hash
    raise NotImplementedError
  end

  def bucket
    self.class.bucket
  end

  def store
    bucket[key] = to_hash
  end

  module ClassMethods
    def bucket
      name = self.name.split('Storage').first.downcase
      @bucket ||= db_client.bucket(name)
    end

    def db_client
      $riak_client ||= Riak::Client.new(:protocol => "pbc", :pb_port => 8087)
    end
  end
end
