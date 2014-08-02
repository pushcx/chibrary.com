require_relative '../rspec'
require_relative '../../value/summary'
require_relative '../../model/message'
require_relative '../../model/summary_container'

module Chibrary

describe SummaryContainer do
  describe 'effective fields' do
    class FieldsValue
      def call_number ; 'callnumb' ; end
      def date ; Time.new(2013, 11, 21) ; end
      def n_subject ; 'cats' ; end
      def blurb ; 'some text' ; end
    end
    let(:c) { SummaryContainer.new 'c@example.com', FieldsValue.new }

    it '#call_number' do
      expect(c.call_number).to eq('callnumb')
    end

    it '#date' do
      expect(c.date).to eq(Time.new(2013, 11, 21))
    end

    it '#n_subject' do
      expect(c.n_subject).to eq('cats')
    end

    it '#blurb' do
      expect(c.blurb).to eq('some text')
    end
  end

  describe '#summarize is a no-op' do
    it 'returns itself' do
      s = Summary.new 'callnumb', 'from@example.com', 'subject', Time.now, 'blurb'
      c = SummaryContainer.new 'c@example.com', s
      expect(c.summarize).to be(c)
    end
  end

  describe '#messagize converts a SummaryContainer into equivalent MessageContainer' do
    let(:m1) { Message.from_string "Subject: m1\n\nm1", 'callnum1' }
    let(:m2) { Message.from_string "Subject: m2\n\nm2", 'callnum2' }
    let(:messages) { { 'callnum1' => m1, 'callnum2' => m2 } }

    let(:s1) { Summary.new 'callnum1', '1@example.com', 'm1', Time.now, 'blurb' }
    let(:s2) { Summary.new 'callnum2', '2@example.com', 'm2', Time.now, 'blurb' }
    let(:c1) { SummaryContainer.new 'c1@example.com', s1 }
    let(:c2) { SummaryContainer.new 'c2@example.com', s2 }
    before   { c1.adopt c2 }
    subject  { c1.messagize messages }

    expect_it { to be_a MessageContainer }
    it { expect(subject.value).to be_a(Message) }
    it { expect(subject.call_number).to eq('callnum1') }
    it { expect(subject.subject).to eq('m1') }

    it { expect(subject.children.first.value).to be_a(Message) }
    it { expect(subject.children.first.call_number).to eq('callnum2') }
    it { expect(subject.children.first.subject).to eq('m2') }
  end

end

end # Chibrary
