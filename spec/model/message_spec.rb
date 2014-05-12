require_relative '../rspec'
require_relative '../../model/message'
require_relative '../../model/list'

describe Message do
  describe 'delegates to email for fields' do
    let(:now) { Time.now }
    let(:email) { double('email', n_subject: 'foo', date: now).as_null_object }
    let(:message) { Message.new(email, 'callnumb') }

    it { expect(message.n_subject).to eq('foo') }
    it { expect(message.date).to eq(now) }
  end

  describe '#likely_split_thread?' do
    # delegates to subejct and #body_quotes?, does not need testing
  end

  describe '#body_quotes?' do
    it 'does when there are quoted lines' do
      m = Message.from_string "\n\n> body\ntext", 'callnumb'
      expect(m.body_quotes?).to be_true
    end

    it 'does not when there are no quoted liens' do
      m = Message.from_string "\n\nbody\ntext", 'callnumb'
      expect(m.body_quotes?).to be_false
    end
  end

  describe '#==' do
    it 'is the same if the fields are the same' do
      m1 = Message.from_string "\n\nBody", 'callnumb', 'source', List.new('list')
      m2 = Message.from_string "\n\nBody", 'callnumb', 'source', List.new('list')
      expect(m2).to eq(m1)
    end
  end

  describe '::from_string' do
    it 'creates emails' do
      m = Message.from_string 'email', 'callnumb'
      expect(m.email).to be_an(Email)
    end
  end

  describe '::from_message' do
    it 'copies fields' do
      m1 = Message.from_string "\n\nBody", 'callnumb', 'source', List.new('list')
      m2 = Message.from_message m1
      expect(m2.email.body).to eq(m1.email.body)
      expect(m2.call_number).to eq(m1.call_number)
      expect(m2.source).to eq(m2.source)
      expect(m2.list).to eq(m1.list)
    end
  end
end
