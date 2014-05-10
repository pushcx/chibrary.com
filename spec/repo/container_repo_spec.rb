require_relative '../rspec'
require_relative '../../repo/container_repo'

class TContainerRepo
  include ContainerRepo
end

FakeContainer = Struct.new(:key, :value, :children) do
end

describe TContainerRepo do
  context 'instantiated with a Container' do
    class MessageLikeContainer < FakeContainer
      def slug ; 'slug' ; end
      def date ; Time.new(2014, 1) ; end
      def call_number ; 'callnumber' ; end
    end

    it 'extracts a month key based on the container' do
      c = MessageLikeContainer.new
      expect(TContainerRepo.new(c).extract_month_key).to eq('slug/2014/01')
    end

    describe '#serialize' do
      class HashesValuesContainerRepo
        include ContainerRepo
        def serialize_value ; { value: 'value' } ; end
      end
      let(:c2) { FakeContainer.new 'c2key', 'c2@example.com', [] }
      let(:c1) { FakeContainer.new 'c1key', 'c1@example.com', [c2] }
      let(:container_repo) { HashesValuesContainerRepo.new(c1) }
      subject { container_repo.serialize }

      it { expect(subject[:key]).to eq('c1key') }
      it { expect(subject[:value]).to eq({ value: 'value' }) }
      it { expect(subject[:children].first[:key]).to eq('c2key') }
    end

    class EmptyTreeContainer
      def empty_tree? ; true ; end
    end

    it '#store does not hit Riak with an empty tree' do
      TContainerRepo.new(EmptyTreeContainer.new).store
    end
  end

  describe 'incomplete user' do
    it 'raises on calls to #serialize_value' do
      expect {
        TContainerRepo.new(nil).serialize_value
      }.to raise_error(NotImplementedError)
    end

    it 'raises on calls to ::deserialize_value' do
      expect {
        TContainerRepo.deserialize_value(nil)
      }.to raise_error(NotImplementedError)
    end
  end

  describe '::build_month_key' do
    it 'delegates key building to the sym' do
      key = TContainerRepo.build_month_key(Sym.new('slug', 2014, 5))
      expect(key).to eq('slug/2014/05')
    end
  end

  class UnHashesValuesContainerRepo
    include ContainerRepo
    def self.deserialize_value(h) ; FakeContainer.new 'callnumber', 'value' ; end
    def self.container_class ; FakeContainer ; end
  end

  describe '::deserialize' do
    it 'creates Containers' do
      container = UnHashesValuesContainerRepo.deserialize({
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
      UnHashesValuesContainerRepo.should_receive(:bucket).and_return(bucket)
      container = UnHashesValuesContainerRepo.find('callnumber')
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
      UnHashesValuesContainerRepo.stub(:bucket).and_return(bucket)
      threads = UnHashesValuesContainerRepo.month(Sym.new('slug', 2014, 1))
      expect(threads[0].key).to eq('callnumbr1')
      expect(threads[1].key).to eq('callnumbr2')
    end

    it 'returns an empty array for a month with nothing' do
      bucket = double('bucket')
      bucket.should_receive(:get_index).and_return([])
      TContainerRepo.stub(:bucket).and_return(bucket)
      expect(TContainerRepo.month(Sym.new('slug', 2014, 1))).to eq([])
    end
  end
end
