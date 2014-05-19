require 'ostruct'

require_relative '../rspec'
require_relative '../../value/summary'

describe Summary do
  describe '::from copies fields' do
    let(:now)     { Time.now }
    let(:message) { double(call_number: 'callnumb', from: 'From', n_subject: 'foo', date: now, body: 'body') }
    let(:summary) { Summary.from message }

    it { expect(summary.call_number).to eq('callnumb') }
    it { expect(summary.from).to eq('From') }
    it { expect(summary.n_subject).to eq('foo') }
    it { expect(summary.date).to eq(now) }
    it { expect(summary.blurb).to eq('body') }
  end
end
