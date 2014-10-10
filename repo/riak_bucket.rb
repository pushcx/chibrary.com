require 'active_support/core_ext/hash'
require 'forwardable'
require 'riak'

module Chibrary

class RiakBucket
  extend Forwardable
  def_delegators :@bucket, :get_index, :name, :new

  def initialize bucket
    @bucket = bucket
  end

  def [] key
    data = @bucket[key.to_s].data
    data.deep_symbolize_keys! if data.is_a? Hash
    data
  rescue Riak::ProtobuffsFailedRequest => e
    # show backtrace from before riak
    bt = e.backtrace[e.backtrace.index(e.backtrace.detect { |s| s !~ /\/gems\// })..-1]
    raise NotFound, "Bucket #{@bucket.name} Key #{key} not found", bt
  end

  def []= key, value
    o = @bucket.new key.to_s
    o.data = value
    o.store
  end

  def delete key
    @bucket.delete key.to_s
  end

  def get_any keys
    @bucket.get_many(keys.map(&:to_s)).map do |k, v|
      v &&= v.data.is_a?(Hash) ? v.data.deep_symbolize_keys : v.data
      [k, v]
    end.to_h
  end

  def get_all keys
    objs = get_any(keys)
    missing = objs.select { |k, v| v.nil? }
    raise NotFound, "Bucket #{@bucket.name} key(s) not found: #{missing.keys.join(', ')}" if missing.any?
    objs
  end
end

end # Chibrary
