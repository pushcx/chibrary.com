require_relative '../../rspec'
require_relative '../../../model/storage/container_storage'

describe ContainerStorage do
  context 'instantiated with a Container' do
    it 'extracts a key based on the container' do
      c = Container.new FakeStorableMessage.new('c@example.com')
      expect(ContainerStorage.new(c).extract_key).to eq('/slug/2013/11/callnumber')
    end

    describe 'generating a hash' do
      let(:c1) { Container.new 'c1@example.com', 'c1key' }
      let(:c2) { Container.new 'c2@example.com', 'c2key' }
      before { c1.adopt c2 }
      let(:container_storage) { ContainerStorage.new(c1) }
      subject { container_storage.to_hash }

      it { expect(subject[:message_id]).to eq('c1@example.com') }
      it { expect(subject[:message_key]).to eq('c1key') }
      it { expect(subject[:children].first[:message_id]).to eq('c2@example.com') }
    end
  end

  describe '::build_key' do
    it 'builds a key based on slug, year, month and call_number' do
      expect(ContainerStorage.build_key('slug', 2013, 9, 'callnumber')).to eq('/slug/2013/09/callnumber')
    end
  end

  describe '::from_hash' do
    it 'creates Containers' do
      container = ContainerStorage.from_hash({
        message_id: 'c@example.com',
        message_key: 'key',
        children: [],
      })
      expect(container.message_id).to eq('c@example.com')
      expect(container.message_key).to eq('key')
    end
  end

  describe '::find' do
    it 'instantiates a Container from the bucket' do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('/slug/2013/11/callnumber').and_return({
        message_id: 'c@example.com',
        message_key: 'key',
        children: [],
      })
      ContainerStorage.should_receive(:bucket).and_return(bucket)
      container = ContainerStorage.find('slug', 2013, 11, 'callnumber')
      expect(container).to be_a(Container)
      expect(container.message_id).to eq('c@example.com')
    end
  end
end
