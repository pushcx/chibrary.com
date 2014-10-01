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
      expect(MessageRepo.new(m).extract_key).to eq('callnumb')
    end

    describe '#serialize' do
      let(:m) { FakeStorableMessage.new }
      let(:message_repo) { MessageRepo.new(m) }
      before { EmailRepo.should_receive(:new).and_return(double('email_repo', serialize: {})) }
      subject { message_repo.serialize }

      it { expect(subject[:source]).to eq('source') }
      it { expect(subject[:call_number]).to eq('callnumb') }
      it { expect(subject[:email]).to eq({}) }
      it { expect(subject[:overlay]).to eq({}) }
    end

    describe "#indexes" do
      it 'indexes a valid message_id' do
        mr = MessageRepo.new(FakeStorableMessage.new)
        expect(mr.indexes[:id_hash_bin]).to eq(Base64.strict_encode64('id@example.com'))
      end

      it 'indexes the sym' do
        mr = MessageRepo.new(FakeStorableMessage.new)
        expect(mr.indexes[:sym_bin]).to eq('slug/2014/09')
      end

      it 'indexes the slug + timestamp' do
        mr = MessageRepo.new(FakeStorableMessage.new)
        expect(mr.indexes[:slug_timestamp_bin]).to eq('slug_1385013600')
      end

      it 'indexes the author email' do
        mr = MessageRepo.new(FakeStorableMessage.new)
        expect(mr.indexes[:author_bin]).to eq(Base64.strict_encode64('from@example.com'))
      end
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
      slug: 'slug',
      source: 'source',
      list_slug: 'slug',
      overlay: {
        message_id: 'overlay@example.com',
      },
    })
    expect(message.call_number).to eq('callnumb')
    expect(message.slug).to eq('slug')
    expect(message.source).to eq('source')
    expect(message.message_id.to_s).to eq('overlay@example.com')
  end
end

end # Chibrary
