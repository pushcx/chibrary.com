require 'ostruct'

require_relative '../rspec'
require_relative '../../model/summary'

describe Summary do
  describe '::new' do
    it 'raises on invalid call_numbers' do
      expect {
        Summary.new 'foo', nil, Time.now, 'body'
      }.to raise_error(ArgumentError, /call_number/)
    end
  end

  describe '::from copies fields' do
    let(:now)     { Time.now }
    let(:message) { double(call_number: 'callnumber', n_subject: 'foo', date: now, body: 'body') }
    let(:summary) { Summary.from message }

    it { expect(summary.call_number).to eq('callnumber') }
    it { expect(summary.n_subject).to eq('foo') }
    it { expect(summary.date).to eq(now) }
    it { expect(summary.blurb).to eq('body') }
  end
end
