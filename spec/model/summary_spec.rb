require 'ostruct'

require_relative '../rspec'
require_relative '../../model/summary'

describe Summary do
  describe '::from copies fields' do
    let(:now)     { Time.now }
    let(:message) { double(call_number: 'callnumb', n_subject: 'foo', date: now, body: 'body') }
    let(:summary) { Summary.from message }

    it { expect(summary.call_number).to eq('callnumb') }
    it { expect(summary.n_subject).to eq('foo') }
    it { expect(summary.date).to eq(now) }
    it { expect(summary.blurb).to eq('body') }
  end
end
