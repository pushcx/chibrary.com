require_relative '../../rspec'
require_relative '../../../model/message'
require_relative '../../../model/message_container'

describe MessageContainer do
  describe '#summarize converts a MessageContainer into equivalent SummaryContainer' do
    let(:m1) { Message.from_string "Subject: m1\n\nm1", 'callnumbr1' }
    let(:m2) { Message.from_string "Subject: m2\n\nm2", 'callnumbr2' }
    let(:c1) { MessageContainer.new 'c1@example.com', m1 }
    let(:c2) { MessageContainer.new 'c2@example.com', m2 }
    before   { c1.adopt c2 }
    subject  { c1.summarize }

    expect_it { to be_a MessageContainer }
    it { expect(subject.value).to be_a(Summary) }
    it { expect(subject.call_number).to eq('callnumbr1') }
    it { expect(subject.n_subject).to eq('m1') }

    it { expect(subject.children.first.value).to be_a(Summary) }
    it { expect(subject.children.first.call_number).to eq('callnumbr2') }
    it { expect(subject.children.first.n_subject).to eq('m2') }
  end
end
