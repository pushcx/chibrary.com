require 'forwardable'
require 'riak'

class RiakBucket
  extend Forwardable
  def_delegators :@bucket, :name, :new

  def initialize bucket
    @bucket = bucket
  end

  def [] key
    @bucket[key]
  rescue Riak::ProtobuffsFailedRequest
    raise NotFound
  end

  def []= key, value
    o = @bucket.new key
    o.data = value
    o.store
  end
end
