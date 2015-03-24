require_relative 'riak_repo'
require_relative '../entity/list'

module Chibrary

class ListRepo
  include RiakRepo

  attr_reader :list

  def initialize list
    @list = list
  end

  def extract_key
    list.slug.to_s
  end

  def self.build_key slug
    slug.to_s
  end

  def serialize
    {
      slug:        list.slug.to_s,
      name:        list.name,
      description: list.description,
      homepage:    list.homepage,
    }
  end

  def indexes
    {
      slug_bin: list.slug.to_s,
    }
  end

  def self.deserialize h
    List.new h[:slug], h[:name], h[:description], h[:homepage]
  end

  def self.find slug
    key = build_key(slug)
    hash = bucket[key]
    deserialize(hash)
  end

  def self.for slug, possible_list_addresses
    find slug
  rescue NotFound
    ListAddressRepo.find_list_by_addresses(possible_list_addresses)
  end

  def self.all
    keys = bucket.get_index('slug_bin', '0'..'z')
    bucket.get_all(keys).map { |k, h| deserialize h }
  end
end

end # Chibrary
