require_relative 'riak_repo'
require_relative '../value/slug'
require_relative '../model/list'
require_relative 'list_repo'

module Chibrary

class ListAddressRepo
  include RiakRepo

  def self.addresses_match_slug? addresses, slug
    bucket.get_any(addresses).any? { |k, v| v == slug }
  end

  def self.find_list_by_address address
    slug = Slug.new bucket[address]
    ListRepo.find(slug)
  rescue NotFound
    NullList.new
  end

  def self.find_list_by_addresses addresses
    matched = bucket.get_any(addresses).select { |k, v| v.present? }
    return ListRepo.find(matched.values.first) if matched.any?
    NullList.new
  end
end

end # Chibrary
