require_relative 'riak_storage'
require_relative '../list'
require_relative 'list_storage'

class ListAddressStorage
  include RiakStorage

  # maybe this is hinky, but no one actually care to hang onto the
  # intermediate slug and look up the List themselves
  def self.find_list_by_address address
    slug = bucket[address]
    ListStorage.find(slug)
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
