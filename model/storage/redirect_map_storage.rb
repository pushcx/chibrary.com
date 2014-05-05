require_relative 'riak_storage'
require_relative '../redirect_map'

class RedirectMapStorage
  include RiakStorage

  attr_reader :redirect_map

  def initialize redirect_map
    @redirect_map = redirect_map
  end

  def extract_key
    self.class.build_key redirect_map.sym
  end

  def serialize
    redirect_map.redirects
  end

  def self.build_key sym
    sym.to_key
  end

  def self.find sym
    key = build_key(sym)
    redirects = bucket[key]
    RedirectMap.new sym, redirects
  rescue NotFound
    RedirectMap.new sym
  end

end
