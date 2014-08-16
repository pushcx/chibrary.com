require_relative 'riak_repo'
require_relative '../value/slug'
require_relative '../model/list'
require_relative 'list_repo'

module Chibrary

class ListAddressRepo
  include RiakRepo

  # maybe this is hinky, but no one actually care to hang onto the
  # intermediate slug and look up the List themselves
  def self.find_list_by_address address
    slug = Slug.new bucket[address]
    ListRepo.find(slug)
  rescue NotFound
    NullList.new
  end

  def self.find_list_by_addresses addresses
    list = NullList.new
    addresses.each do |address|
      list = find_list_by_address address
      return list unless list.null_list?
    end
    list
  end
end

end # Chibrary
