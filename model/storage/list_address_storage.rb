require_relative 'list_storage'

class ListAddressStorage
  include RiakStorage

  # maybe this is hinky, but no one actually care to hang onto the
  # intermediate slug and look up the List themselves
  def self.find_list_by_address address
    slug = bucket[address]
    ListStorage.find(slug)
  rescue Riak::ProtobuffsFailedRequest
    nil
  end
end
