require 'time'

require_relative '../rspec'
require_relative '../../value/summary'
require_relative '../../repo/summary_repo'

module Chibrary

describe SummaryRepo do
  let(:now) { Time.now.utc }

  context 'instantiated with a Summary' do
    describe '#serialize' do
      let(:summary) { Summary.new('callnumb', '1@example.com', 'From', 'foo', now, 'body') }
      subject { SummaryRepo.new(summary).serialize }

      it { expect(subject[:call_number]).to eq('callnumb') }
      it { expect(subject[:message_id]).to eq('1@example.com') }
      it { expect(subject[:from]).to eq('From') }
      it { expect(subject[:n_subject]).to eq('foo') }
      it { expect(subject[:date]).to eq(now.rfc2822) }
      it { expect(subject[:blurb]).to eq('body') }
    end
  end

  describe '::deserialize' do
    it 'loads from hash' do
      s = SummaryRepo.deserialize({
        call_number: 'callnumb',
        message_id: '1@example.com',
        from: 'From',
        n_subject: 'subject',
        date: now.rfc2822,
        blurb: 'blurb',
      })
      expect(s.call_number).to eq('callnumb')
      expect(s.message_id).to eq('1@example.com')
      expect(s.from).to eq('From')
      expect(s.n_subject).to eq('subject')
      expect(s.date.to_s).to eq(now.to_s)
      expect(s.blurb).to eq('blurb')
    end
  end
end

end # Chibrary
