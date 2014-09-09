require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../repo/message_repo'

module Chibrary

class EmailRepo ; end

describe MessageRepo do
  let(:sym) { Sym.new('slug', 2014, 6) }

  context 'instantiated with a Message and Sym' do
    it '#extract_key' do
      m = FakeStorableMessage.new
      expect(MessageRepo.new(m, sym).extract_key).to eq('callnumb')
    end

    describe '#serialize' do
      let(:m) { FakeStorableMessage.new }
      let(:message_repo) { MessageRepo.new(m, sym) }
      before { EmailRepo.should_receive(:new).and_return(double('email_repo', serialize: {})) }
      subject { message_repo.serialize }

      it { expect(subject[:source]).to eq('source') }
      it { expect(subject[:call_number]).to eq('callnumb') }
      it { expect(subject[:email]).to eq({}) }
      it { expect(subject[:overlay]).to eq({}) }
    end

    describe '#dont_overwrite_if_already_stored' do
      it 'returns true if message is stored' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', exists?: true))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(true)
      end

      it 'returns false if message is not stored' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::DONT)
        ms.stub(:bucket).and_return(double('bucket', exists?: false))
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end

      it 'returns false if overwrite is not set to DONT' do
        m = FakeStorableMessage.new
        ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::DO)
        expect(ms.dont_overwrite_if_already_stored('key')).to eq(false)
      end
    end

    describe '#guard_against_error_overwrite' do
      it 'raises if the message is already stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', exists?: true))
          ms.guard_against_error_overwrite 'key'
        }.to raise_error(MessageOverwriteError)
      end

      it 'does not raise if the message is not stored' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::ERROR)
          ms.stub(:bucket).and_return(double('bucket', exists?: false))
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end

      it 'does nothing if overwrite is not set to ERROR' do
        m = FakeStorableMessage.new
        expect  {
          ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::DO)
          ms.guard_against_error_overwrite 'key'
        }.not_to raise_error
      end
    end

    describe "#indexes" do
      it 'indexes a valid message_id' do
        mr = MessageRepo.new(FakeStorableMessage.new, sym)
        expect(mr.indexes[:id_hash_bin]).to eq(Base64.strict_encode64('id@example.com'))
      end

      it 'does not index an invalid message_id' do
        mr = MessageRepo.new(FakeStorableMessage.new('bad message id'), sym)
        expect(mr.indexes).to_not have_key(:id_hash_bin)
      end

      it 'indexes the sym' do
        mr = MessageRepo.new(FakeStorableMessage.new, sym)
        expect(mr.indexes[:sym_bin]).to eq('slug/2014/06')
      end

      it 'indexes the slug + timestamp' do
        mr = MessageRepo.new(FakeStorableMessage.new, sym)
        expect(mr.indexes[:slug_timestamp_bin]).to eq('slug_1385013600')
      end

      it 'indexes the author email' do
        mr = MessageRepo.new(FakeStorableMessage.new, sym)
        expect(mr.indexes[:author_bin]).to eq(Base64.strict_encode64('from@example.com'))
      end
    end

    describe '#store' do
      # This makes me with I composed against RiakRepo instead of basically
      # inheriting from it.
      let(:index) { double('index', '[]' => []) }
      let(:riak_obj) { double('riak object', indexes: index).as_null_object }
      let(:bucket) { double('bucket', new: riak_obj, exists?: false) }
      let(:mr) { MessageRepo.new(FakeStorableMessage.new, sym) }
      before { mr.stub(:bucket).and_return(bucket) }

      it 'guards against error overwrite' do
        mr.should_receive(:guard_against_error_overwrite)
        mr.store
      end

      it "doesn't overwrite if already stored" do
        mr.should_receive(:dont_overwrite_if_already_stored)
        mr.store
      end

      it 'invokes super' do
        riak_obj.should_receive(:store)
        mr.store
      end
    end

    it 'does not overwrite when instructed not to' do
      m = FakeStorableMessage.new
      ms = MessageRepo.new(m, sym, MessageRepo::Overwrite::DONT)
      bucket = double('bucket', exists?: true)
      bucket.should_not_receive(:new)
      ms.stub(:bucket).and_return(bucket)
      ms.store
    end

  end

  it '::build_key builds based on call number' do
    expect(MessageRepo.build_key('callnumb')).to eq('callnumb')
  end

  it '::deserialize instantiates messages and emails' do
    EmailRepo.should_receive(:deserialize).with('email').and_return(double('email', message_id: 'id@example.com'))
    message = MessageRepo.deserialize({
      email: 'email',
      call_number: 'callnumb',
      source: 'source',
      list_slug: 'slug',
      overlay: {
        message_id: 'overlay@example.com',
      },
    })
    expect(message.call_number).to eq('callnumb')
    expect(message.source).to eq('source')
    expect(message.message_id.to_s).to eq('overlay@example.com')
  end
end

end # Chibrary
