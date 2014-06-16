require 'active_support/core_ext/hash'
require 'forwardable'
require 'riak'

class RiakBucket
  extend Forwardable
  def_delegators :@bucket, :get_index, :name, :new

  def initialize bucket
    @bucket = bucket
  end

  def [] key
    data = @bucket[key].data
    data.deep_symbolize_keys! if data.is_a? Hash
    data
  rescue Riak::ProtobuffsFailedRequest => e
    # show backtrace from before riak
    bt = e.backtrace[e.backtrace.index(e.backtrace.detect { |s| s !~ /\/gems\// })..-1]
    raise NotFound, "Bucket #{@bucket.name} Key #{key} not found", bt
  end

  def get_many keys
    objs = @bucket.get_many(keys)
    missing = objs.select { |k, v| k.nil? }
    raise NotFound, "Bucket #{@bucket.name} key(s) not found: #{missing.keys.join(', ')}" if missing.any?
    objs.each do |k, v|
      data = v.data
      data.deep_symbolize_keys! if data.is_a? Hash
      objs[k] = data
    end
  end

  def []= key, value
    o = @bucket.new key
    o.data = value
    o.store
  end
end
