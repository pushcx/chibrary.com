require_relative '../../rspec'
require_relative '../../../model/storage/message_storage'

describe MessageStorage do
  context 'instantiated with a Message' do
    it '#extract_key' do
      m = FakeStorableMessage.new
      expect(MessageStorage.new(m).extract_key).to eq('/callnumber')
    end

    describe '#to_hash' do
      let(:m) { FakeStorableMessage.new }
      let(:message_storage) { MessageStorage.new(m) }
      before { EmailStorage.should_receive(:new).and_return(double('email_storage', to_hash: {})) }
      subject { message_storage.to_hash }

      it { expect(subject[:source]).to eq('source') }
      it { expect(subject[:call_number]).to eq('callnumber') }
      it { expect(subject[:message_id]).to eq('id@example.com') }
      it { expect(subject[:list_slug]).to eq('slug') }
      it { expect(subject[:email]).to eq({}) }
    end

    describe '#dont_overwrite_if_already_stored' do
      it 'returns true if message is stored' do
        m = FakeStorableMessage.new
        ms = MessageStorage.new(m, MessageStorage::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', has_key?: true))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(true)
      end

      it 'returns false if message is not stored' do
        m = FakeStorableMessage.new
        ms = MessageStorage.new(m, MessageStorage::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', has_key?: false))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end

      it 'returns false if overwrite is not set to DONT' do
        m = FakeStorableMessage.new
        ms = MessageStorage.new(m, MessageStorage::Overwrite::DO)
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end
    end

    describe '#guard_against_error_overwrite' do
      it 'raises if the message is already stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageStorage.new(m, MessageStorage::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', has_key?: true))
          ms.guard_against_error_overwrite 'key'
        }.to raise_error(MessageOverwriteError)
      end

      it 'does not raise if the message is not stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageStorage.new(m, MessageStorage::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', has_key?: false))
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end

      it 'does nothing if overwrite is not set to ERROR' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageStorage.new(m, MessageStorage::Overwrite::DO)
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end
    end

    describe '#store' do
      RiakObjectDouble = Struct.new(:indexes, :key, :data) do
        def store ; end
      end
      let(:m)  { FakeStorableMessage.new }
      let(:ms) { MessageStorage.new(m, MessageStorage::Overwrite::DO) }
      let(:riak_object) { RiakObjectDouble.new({ 'id_hash_bin' => [], 'lmy_bin' => [], 'from_hash_bin' => [] }) }
      before do
        ms.stub(:bucket).and_return(double('bucket', new: riak_object))
        EmailStorage.stub(:new).and_return({})
      end

      it 'stores a message' do
        riak_object.should_receive(:store)
        ms.store
      end

      it 'indexes the message_id' do
        ms.store
        expect(riak_object.indexes['id_hash_bin']).to eq([Base64.strict_encode64('id@example.com')])
      end

      it 'indexes the list/month/year' do
        ms.store
        expect(riak_object.indexes['lmy_bin']).to eq(['slug/2013/11'])
      end

      it 'indexes the author email' do
        ms.store
        expect(riak_object.indexes['from_hash_bin']).to eq([Base64.strict_encode64('from@example.com')])
      end
    end

    it 'does not overwrite when instructed not to' do
      m = FakeStorableMessage.new
      ms = MessageStorage.new(m, MessageStorage::Overwrite::DONT)
      bucket = double('bucket', has_key?: true)
      bucket.should_not_receive(:new)
      ms.stub(:bucket).and_return(bucket)
      ms.store
    end

  end

  it '::build_key builds based on call number' do
    expect(MessageStorage.build_key('callnumber')).to eq('/callnumber')
  end

  it '::from_hash instantiates messages and emails' do
    EmailStorage.should_receive(:from_hash).with('email').and_return(double('email', message_id: 'id@example.com'))
    message = MessageStorage.from_hash({
      email: 'email',
      call_number: 'callnumber',
      source: 'source',
      list_slug: 'slug',
    })
    expect(message.call_number).to eq('callnumber')
    expect(message.source).to eq('source')
    expect(message.list).to eq(List.new('slug'))
  end

  it '::message_list' do
    bucket = double('bucket')
    bucket.should_receive(:get_index).with('lmy_bin', 'slug/2014/01').and_return(['callnumber'])
    MessageStorage.stub(:bucket).and_return(bucket)
    list = MessageStorage.call_number_list(List.new('slug'), 2014, 1)
    expect(list).to eq([CallNumber.new('callnumber')])
  end
end
