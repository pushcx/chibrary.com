require_relative '../../rspec'
require_relative '../../../model/storage/container_storage'

class TContainerStorage
  include ContainerStorage
end

FakeContainer = Struct.new(:key, :value, :children) do
end

describe TContainerStorage do
  context 'instantiated with a Container' do
    class MessageLikeContainer < FakeContainer
      def slug ; 'slug' ; end
      def date ; Time.new(2014, 1) ; end
      def call_number ; 'callnumber' ; end
    end

    it 'extracts a month key based on the container' do
      c = MessageLikeContainer.new
      expect(TContainerStorage.new(c).extract_month_key).to eq('slug/2014/01')
    end

    describe '#to_hash' do
      class HashesValuesContainerStorage
        include ContainerStorage
        def value_to_hash ; { value: 'value' } ; end
      end
      let(:c2) { FakeContainer.new 'c2key', 'c2@example.com', [] }
      let(:c1) { FakeContainer.new 'c1key', 'c1@example.com', [c2] }
      let(:container_storage) { HashesValuesContainerStorage.new(c1) }
      subject { container_storage.to_hash }

      it { expect(subject[:key]).to eq('c1key') }
      it { expect(subject[:value]).to eq({ value: 'value' }) }
      it { expect(subject[:children].first[:key]).to eq('c2key') }
    end

    class EmptyTreeContainer
      def empty_tree? ; true ; end
    end

    it '#store does not hit Riak with an empty tree' do
      TContainerStorage.new(EmptyTreeContainer.new).store
    end
  end

  describe 'incomplete user' do
    it 'raises on calls to #value_to_hash' do
      expect {
        TContainerStorage.new(nil).value_to_hash
      }.to raise_error(NotImplementedError)
    end

    it 'raises on calls to ::value_from_hash' do
      expect {
        TContainerStorage.value_from_hash(nil)
      }.to raise_error(NotImplementedError)
    end
  end

  describe '::build_month_key' do
    it 'builds a key based on slug, year, month and call_number' do
      expect(TContainerStorage.build_month_key('slug', 2013, 9)).to eq('slug/2013/09')
    end
  end

  class UnHashesValuesContainerStorage
    include ContainerStorage
    def self.value_from_hash(h) ; FakeContainer.new 'callnumber', 'value' ; end
    def self.container_class ; FakeContainer ; end
  end

  describe '::from_hash' do
    it 'creates Containers' do
      container = UnHashesValuesContainerStorage.from_hash({
        key: 'callnumber',
        value: {},
        children: [],
      })
      expect(container.key).to eq('callnumber')
      expect(container.value.key).to eq('callnumber')
    end
  end

  describe '::find' do
    it 'instantiates a Container from the bucket' do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('callnumber').and_return({
        key: 'callnumber',
        value: { message: 'totes fake' },
        children: [],
      })
      UnHashesValuesContainerStorage.should_receive(:bucket).and_return(bucket)
      container = UnHashesValuesContainerStorage.find('callnumber')
      expect(container).to be_a(FakeContainer)
      expect(container.key).to eq('callnumber')
    end
  end

  describe '::month' do
    it 'loads all threads in the month' do
      bucket = double('bucket')
      bucket.should_receive(:get_index).and_return(['callnumbr1', 'callnumbr2'])
      bucket.should_receive(:[]).with('callnumbr1').and_return({
        key: 'callnumbr1',
        value: { message: 'first message' },
        children: [],
      })
      bucket.should_receive(:[]).with('callnumbr2').and_return({
        key: 'callnumbr2',
        value: { message: 'second message' },
        children: [],
      })
      UnHashesValuesContainerStorage.stub(:bucket).and_return(bucket)
      threads = UnHashesValuesContainerStorage.month('slug', 2014, 1)
      expect(threads[0].key).to eq('callnumbr1')
      expect(threads[1].key).to eq('callnumbr2')
    end

    it 'returns an empty array for a month with nothing' do
      bucket = double('bucket')
      bucket.should_receive(:get_index).and_return([])
      TContainerStorage.stub(:bucket).and_return(bucket)
      expect(TContainerStorage.month('slug', 2014, 1)).to eq([])
    end
  end
end
