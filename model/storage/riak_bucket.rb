require 'forwardable'
require 'riak'
require_relative 'riak_storage'

class RiakBucket
  extend Forwardable
  def_delegators :@bucket, :name

  def initialize bucket
    @bucket = bucket
  end

  def [] key
    @bucket[key]
  rescue Riak::ProtobuffsFailedRequest
    raise NotFound
  end
end
