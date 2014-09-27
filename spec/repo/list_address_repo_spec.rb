require_relative '../rspec'
require_relative '../../repo/list_address_repo'

module Chibrary

describe ListAddressRepo do
  def bucket_stub method, with, retval
    bucket = double('bucket')
    bucket.should_receive(method).with(with).and_return(retval)
    ListAddressRepo.should_receive(:bucket).and_return(bucket)
  end

  describe '::addresses_match_slug?' do
    it 'is true if any address matches slug' do
      bucket_stub :get_any, ['list@example.com'], { 'list@example.com' => 'slug' }
      expect(ListAddressRepo.addresses_match_slug? ['list@example.com'], 'slug').to be_true
    end

    it 'is not if none do' do
      bucket_stub :get_any, ['list@example.com'], { 'list@example.com' => nil }
      expect(ListAddressRepo.addresses_match_slug? ['list@example.com'], 'slug').to be_false
    end

    it 'is not with no addresses' do
      bucket_stub :get_any, [], {}
      expect(ListAddressRepo.addresses_match_slug? [], 'slug').to be_false
    end
  end

  describe '::find_list_by_address' do
    it 'finds a list' do
      # This am stubbed to death. Am I even testing anything?
      bucket_stub :[], 'list@example.com', 'slug'
      ListRepo.should_receive(:find).with('slug')
      ListAddressRepo.find_list_by_address('list@example.com')
    end

    it 'returns NullList if address not found' do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('bad@example.com').and_raise(NotFound)
      ListAddressRepo.should_receive(:bucket).and_return(bucket)
      list = ListAddressRepo.find_list_by_address('bad@example.com')
      expect(list.null?).to be_true
    end
  end

  describe '::find_list_by_addresses' do
    it 'finds first list from addresses' do
      bucket_stub :get_any, ['list@example.com', 'other@example.com'], { 'list@example.com' => 'slug', 'other@example.com' => 'other' }
      ListRepo.should_receive(:find).with('slug')
      ListAddressRepo.find_list_by_addresses(['list@example.com', 'other@example.com'])
    end

    it 'returns NullList if no address is found' do
      bucket_stub :get_any, ['bad@example.com'], { 'bae@example.com' => nil }
      list = ListAddressRepo.find_list_by_addresses(['bad@example.com'])
      expect(list.null?).to be_true
    end
  end
end

end # Chibrary
