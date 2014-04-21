require_relative '../../rspec'
require_relative '../../../model/storage/list_address_storage'

describe ListAddressStorage do
  describe '::find_list_by_address' do
    it 'finds lists' do
      # This am stubbed to death. Am I even testing anything?
      bucket = double('bucket')
      bucket.should_receive(:[]).with('list@example.com').and_return('slug')
      ListAddressStorage.should_receive(:bucket).and_return(bucket)
      ListStorage.should_receive(:find).with('slug')
      list = ListAddressStorage.find_list_by_address('list@example.com')
    end

    it 'returns nil if address not found' do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('bad@example.com').and_raise(Riak::ProtobuffsFailedRequest.new('a', 'b'))
      ListAddressStorage.should_receive(:bucket).and_return(bucket)
      list = ListAddressStorage.find_list_by_address('bad@example.com')
    end
  end
end
