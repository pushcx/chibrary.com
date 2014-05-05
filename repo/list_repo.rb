require_relative 'riak_repo'
require_relative '../model/list'

class ListRepo
  include RiakRepo

  attr_reader :list

  def initialize list
    @list = list
  end

  def extract_key
    list.slug
  end

  def self.build_key slug
    slug
  end

  def serialize
    {
      slug:        list.slug,
      name:        list.name,
      description: list.description,
      homepage:    list.homepage,
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
end
