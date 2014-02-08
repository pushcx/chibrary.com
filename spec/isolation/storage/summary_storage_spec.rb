require 'time'

require_relative '../../rspec'
require_relative '../../../model/storage/summary_storage'

describe SummaryStorage do
  context 'instantiated with a Message' do
    describe '#to_hash' do
      let(:now) { Time.now }
      let(:summary) { OpenStruct.new(call_number: 'callnumber', n_subject: 'foo', date: now, blurb: 'body') }
      subject { SummaryStorage.new(summary).to_hash }

      it { expect(subject[:call_number]).to eq('callnumber') }
      it { expect(subject[:n_subject]).to eq('foo') }
      it { expect(subject[:date]).to eq(now.rfc2822) }
      it { expect(subject[:blurb]).to eq('body') }
    end
  end
end
