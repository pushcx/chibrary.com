require_relative '../rspec'
require_relative '../../repo/list_address_repo'

describe ListAddressRepo do
  describe '::find_list_by_address' do
    it 'finds lists' do
      # This am stubbed to death. Am I even testing anything?
      bucket = double('bucket')
      bucket.should_receive(:[]).with('list@example.com').and_return('slug')
      ListAddressRepo.should_receive(:bucket).and_return(bucket)
      ListRepo.should_receive(:find).with('slug')
      list = ListAddressRepo.find_list_by_address('list@example.com')
    end

    it 'returns nil if address not found' do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('bad@example.com').and_raise(NotFound)
      ListAddressRepo.should_receive(:bucket).and_return(bucket)
      list = ListAddressRepo.find_list_by_address('bad@example.com')
    end
  end
end
