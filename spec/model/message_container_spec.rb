require_relative '../rspec'
require_relative '../../model/message_container'

describe MessageContainer do
  describe 'sorting' do
    class DateValue
      attr_reader :date
      def initialize date
        @date = date
      end
    end

    it 'is based on date' do
      c1 = MessageContainer.new 'id', DateValue.new(Time.now - 1)
      c2 = MessageContainer.new 'id', DateValue.new(Time.now)
      expect([c2, c1].sort).to eq([c1, c2])
    end
  end

  describe '#adopt' do
    # MessageContainer differs from Container here
    it 'does not adopt an already-parented container' do
      c1 = MessageContainer.new 'c1@example.com'
        c2 = MessageContainer.new 'c2@example.com'
        c1.adopt c2

      other = MessageContainer.new 'other@example.com'
      other.adopt(c2)
      expect(c2.parent).to be(c1)
      expect(other.children).to be_empty
    end

    it 'trust a message about its parent when adopting' do
      class FakeAdoptMessage < FakeMessage
        def references ; ['c2@example.com'] ; end
      end
      c1 = MessageContainer.new 'c1@example.com', FakeMessage.new('c1@example.com')
      c2 = MessageContainer.new 'c2@example.com', FakeMessage.new('c2@example.com')
      c3 = MessageContainer.new 'c3@example.com', FakeAdoptMessage.new('c3@example.com')
      c1.adopt c3
      c1.adopt c2
      c2.adopt c3
      expect(c3.parent).to eq(c2)
      expect(c1.children).to eq([c2])
      expect(c2.children).to eq([c3])
    end
  end

  describe '#likely_split_thread?' do
    # delegates to message and does not need testing
  end

  describe 'aliasing' do
    it 'aliases #message_id to #key' do
      mc = MessageContainer.new 'foo@example.com'
      expect(mc.message_id).to eq('foo@example.com')
    end

    it 'aliases #message to #value' do
      message = FakeMessage.new('fake@example.com')
      mc = MessageContainer.new 'fake@example.com', message
      expect(mc.message).to eq(message)
    end

    it 'aliases #message= to #value=' do
      message = FakeMessage.new('fake@example.com')
      mc = MessageContainer.new 'fake@example.com'
      mc.message = message
      expect(mc.value).to eq(message)
    end
  end

  describe "#subject_shorter_than?" do
    # this is too stupidly simple to test
  end

  describe 'effective fields' do
    class FieldsValue
      def call_number ; 'callnumber' ; end
      def date ; Time.new(2013, 11, 21) ; end
      def subject ; 'Re: cats' ; end
      def n_subject ; 'cats' ; end
    end
    let(:c) { MessageContainer.new 'c@example.com', FieldsValue.new }

    it '#call_number' do
      expect(c.call_number).to eq('callnumber')
    end

    it '#date' do
      expect(c.date).to eq(Time.new(2013, 11, 21))
    end

    it '#subject' do
      expect(c.subject).to eq('Re: cats')
    end

    it '#n_subject' do
      expect(c.n_subject).to eq('cats')
    end
  end

  describe '#message=' do
    it 'rejects messages with different ids' do
      c = MessageContainer.new 'container@example.com'
      m = FakeMessage.new('fake@example.com')
      expect {
        c.message = m
      }.to raise_error(/doesn't match/)
    end
  end

  describe '#summarize converts a MessageContainer into equivalent SummaryContainer' do
    let(:m1) { Message.from_string "Subject: m1\n\nm1", 'callnumbr1' }
    let(:m2) { Message.from_string "Subject: m2\n\nm2", 'callnumbr2' }
    let(:c1) { MessageContainer.new 'c1@example.com', m1 }
    let(:c2) { MessageContainer.new 'c2@example.com', m2 }
    before   { c1.adopt c2 }
    subject  { c1.summarize }

    expect_it { to be_a SummaryContainer }
    it { expect(subject.value).to be_a(Summary) }
    it { expect(subject.call_number).to eq('callnumbr1') }
    it { expect(subject.n_subject).to eq('m1') }

    it { expect(subject.children.first.value).to be_a(Summary) }
    it { expect(subject.children.first.call_number).to eq('callnumbr2') }
    it { expect(subject.children.first.n_subject).to eq('m2') }
  end

  describe '#to_s' do
    it 'identifies empty containers' do
      c = MessageContainer.new('c@example.com')
      expect(c.to_s).to include('empty')
    end

    it 'includes message id with a message' do
      c = MessageContainer.new('c@example.com', FakeMessage.new('c@example.com'))
      expect(c.to_s).to include('c@example.com')
    end
  end
end
