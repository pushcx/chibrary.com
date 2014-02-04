require_relative '../../rspec'
require_relative '../../../model/message_container'

describe MessageContainer do
  describe '#likely_split_thread?' do
    it 'considers an empty container likely split' do
      c = MessageContainer.new('c@example.com')
      expect(c).to be_likely_split_thread
    end

    it 'considers a message with a Re: subject likely split' do
      class FakeReplyMessage < FakeMessage
        def subject_is_reply? ; true ; end
      end

      c = MessageContainer.new FakeReplyMessage.new
      expect(c).to be_likely_split_thread
    end

    it 'considers a message with quoting likely split' do
      class FakeQuotingMessage < FakeMessage
        def subject_is_reply? ; false ; end
        def body ; "> foo\n\noh i totes agree" ; end
      end

      c = MessageContainer.new FakeQuotingMessage.new
      expect(c).to be_likely_split_thread
    end
  end

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

  describe '#slug' do
    it 'fetches the list slug' do
      c = MessageContainer.new 'c@example.com', FakeMessage.new('c@example.com')
      expect(c.slug).to eq('slug')
    end

    it 'falls back to empty string' do
      fm = FakeMessage.new('c@example.com')
      def fm.list ; nil ; end
      c = MessageContainer.new 'c@example.com', fm
      expect(c.slug).to eq('')
    end
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

  describe '#message=' do
    it 'rejects messages with different ids' do
      c = MessageContainer.new 'container@example.com'
      m = FakeMessage.new('fake@example.com')
      expect {
        c.message = m
      }.to raise_error(/doesn't match/)
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

end
