require_relative 'riak_repo'
require_relative '../value/slug'
require_relative '../model/list'
require_relative 'list_repo'

module Chibrary

class NoListFoundForMessage < RuntimeError ; end

class ListAddressRepo
  include RiakRepo

  def self.find_list_by_addresses addresses
    slug = bucket.get_any(addresses).values.find { |v| v.present? }
    ListRepo.find(slug)
  end
end

end # Chibrary
