require_relative '../rspec'
require_relative '../../repo/list_address_repo'

module Chibrary

describe ListAddressRepo do
  def bucket_stub method, with, retval
    bucket = double('bucket')
    bucket.should_receive(method).with(with).and_return(retval)
    ListAddressRepo.should_receive(:bucket).and_return(bucket)
  end

  describe '::find_list_by_addresses' do
    it 'finds first list from addresses' do
      bucket_stub :get_any, ['list@example.com', 'other@example.com'], { 'list@example.com' => 'slug', 'other@example.com' => 'other' }
      ListRepo.should_receive(:find).with('slug')
      ListAddressRepo.find_list_by_addresses(['list@example.com', 'other@example.com'])
    end

    it 'raises if no address is found' do
      bucket_stub :get_any, ['bad@example.com'], { 'bad@example.com' => nil }
      ListRepo.stub(:find).with(nil).and_raise(NotFound)
      expect {
        list = ListAddressRepo.find_list_by_addresses(['bad@example.com'])
      }.to raise_error NotFound
    end
  end
end

end # Chibrary
