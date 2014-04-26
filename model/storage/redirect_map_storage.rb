require_relative 'riak_storage'
require_relative '../redirect_map'

class RedirectMapStorage
  include RiakStorage

  attr_reader :redirect_map

  def initialize redirect_map
    @redirect_map = redirect_map
  end

  def extract_key
    self.class.build_key redirect_map.slug, redirect_map.year, redirect_map.month
  end

  def serialize
    redirect_map.redirects
  end

  def self.build_key slug, year, month
    "#{slug}/#{year}/%02d" % month
  end

  def self.find slug, year, month
    key = build_key(slug, year, month)
    redirects = bucket[key]
    RedirectMap.new slug, year, month, redirects
  rescue NotFound
    RedirectMap.new slug, year, month
  end

end
