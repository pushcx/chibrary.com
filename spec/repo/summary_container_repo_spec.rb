require_relative '../rspec'
require_relative '../../value/summary'
require_relative '../../model/summary_container'
require_relative '../../repo/summary_repo'
require_relative '../../repo/summary_container_repo'

module Chibrary

describe SummaryRepo do
  describe '#serialize' do
    let(:s1) { Summary.new 'callnum1', 'f1@example.com', 'n 1', Time.now, 'blurb 1' }
    let(:s2) { Summary.new 'callnum2', 'f2@example.com', 'n 2', Time.now, 'blurb 2' }
    let(:c1) { SummaryContainer.new '1@example.com', s1 }
    let(:c2) { SummaryContainer.new '2@example.com', s2 }
    before { c1.adopt c2 }
    subject { SummaryContainerRepo.new(c1).serialize }

    it 'stores the message id key' do
      expect(subject[:key]).to eq('1@example.com')
    end
    it 'stores the summary' do
      expect(subject[:value]).to eq(SummaryRepo.new(s1).serialize)
    end
    it 'stores the child summary' do
      expect(subject[:children].first[:value]).to eq(SummaryRepo.new(s2).serialize)
    end
  end

  describe '::deserialize' do
    let(:s1) { Summary.new 'callnum1', 'f1@example.com', 'n 1', Time.now, 'blurb 1' }
    let(:s2) { Summary.new 'callnum2', 'f2@example.com', 'n 2', Time.now, 'blurb 2' }
    let(:hash) {
      {
        key: '1@example.com',
        value: SummaryRepo.new(s1).serialize,
        children: [
          {
            key: '2@example.com',
            value: SummaryRepo.new(s2).serialize,
            children: [],
          },
        ],
      }
    }
    subject { SummaryContainerRepo.deserialize(hash) }
    it 'creates SummaryContainers' do
      expect(subject).to be_a(SummaryContainer)
    end
    it 'restores message id key' do
      expect(subject.key).to eq('1@example.com')
    end
    it 'restores summary' do
      expect(subject.value).to eq(s1)
    end
    it 'restores child summaries' do
      expect(subject.children.length).to eq(1)
      expect(subject.children.first.value).to eq(s2)
    end
  end
end

end # Chibrary
