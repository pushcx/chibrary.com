require_relative '../../rspec'
require_relative '../../../model/list'
require_relative '../../../value/sym'
require_relative '../../../repo/message_repo'

class EmailRepo ; end

describe MessageRepo do
  context 'instantiated with a Message' do
    it '#extract_key' do
      m = FakeStorableMessage.new
      expect(MessageRepo.new(m).extract_key).to eq('callnumber')
    end

    describe '#serialize' do
      let(:m) { FakeStorableMessage.new }
      let(:message_repo) { MessageRepo.new(m) }
      before { EmailRepo.should_receive(:new).and_return(double('email_repo', serialize: {})) }
      subject { message_repo.serialize }

      it { expect(subject[:source]).to eq('source') }
      it { expect(subject[:call_number]).to eq('callnumber') }
      it { expect(subject[:message_id]).to eq('id@example.com') }
      it { expect(subject[:list_slug]).to eq('slug') }
      it { expect(subject[:email]).to eq({}) }
    end

    describe '#dont_overwrite_if_already_stored' do
      it 'returns true if message is stored' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, MessageRepo::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', exists?: true))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(true)
      end

      it 'returns false if message is not stored' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, MessageRepo::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', exists?: false))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end

      it 'returns false if overwrite is not set to DONT' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, MessageRepo::Overwrite::DO)
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end
    end

    describe '#guard_against_error_overwrite' do
      it 'raises if the message is already stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, MessageRepo::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', exists?: true))
          ms.guard_against_error_overwrite 'key'
        }.to raise_error(MessageOverwriteError)
      end

      it 'does not raise if the message is not stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, MessageRepo::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', exists?: false))
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end

      it 'does nothing if overwrite is not set to ERROR' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, MessageRepo::Overwrite::DO)
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end
    end

    describe '#store' do
      RiakObjectDouble = Struct.new(:indexes, :key, :data) do
        def store ; end
      end
      let(:m)  { FakeStorableMessage.new }
      let(:ms) { MessageRepo.new(m, MessageRepo::Overwrite::DO) }
      let(:riak_object) { RiakObjectDouble.new({ 'id_hash_bin' => [], 'sym_bin' => [], 'author_bin' => [] }) }
      before do
        ms.stub(:bucket).and_return(double('bucket', new: riak_object))
        EmailRepo.stub(:new).and_return(double('EmailRepo', serialize: {}))
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
        expect(riak_object.indexes['sym_bin']).to eq(['slug/2013/11'])
      end

      it 'indexes the author email' do
        ms.store
        expect(riak_object.indexes['author_bin']).to eq([Base64.strict_encode64('from@example.com')])
      end
    end

    it 'does not overwrite when instructed not to' do
      m = FakeStorableMessage.new
      ms = MessageRepo.new(m, MessageRepo::Overwrite::DONT)
      bucket = double('bucket', exists?: true)
      bucket.should_not_receive(:new)
      ms.stub(:bucket).and_return(bucket)
      ms.store
    end

  end

  it '::build_key builds based on call number' do
    expect(MessageRepo.build_key('callnumber')).to eq('callnumber')
  end

  it '::deserialize instantiates messages and emails' do
    EmailRepo.should_receive(:deserialize).with('email').and_return(double('email', message_id: 'id@example.com'))
    message = MessageRepo.deserialize({
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
    bucket.should_receive(:get_index).with('sym_bin', 'slug/2014/01').and_return(['callnumber'])
    MessageRepo.stub(:bucket).and_return(bucket)
    list = MessageRepo.call_number_list(Sym.new('slug', 2014, 1))
    expect(list).to eq([CallNumber.new('callnumber')])
  end
end
