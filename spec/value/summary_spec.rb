require 'ostruct'

require_relative '../rspec'
require_relative '../../value/summary'

module Chibrary

describe Summary do
  describe '#no_archive?' do
    it 'is always false to match _thread_list partial' do
      s = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'subject', Time.now, 'blurb'
      expect(s.no_archive?).to eq(false)
    end
  end

  describe '::from copies fields' do
    let(:now)     { Time.now }
    let(:message) { double(call_number: 'callnumb', message_id: '1@example.com', from: 'From', n_subject: 'foo', date: now, body: 'body') }
    let(:summary) { Summary.from message }

    it { expect(summary.call_number).to eq('callnumb') }
    it { expect(summary.message_id).to eq('1@example.com') }
    it { expect(summary.from).to eq('From') }
    it { expect(summary.n_subject).to eq('foo') }
    it { expect(summary.date).to eq(now) }
    it { expect(summary.blurb).to eq('body') }
  end

  describe '#==' do
    let(:now) { Time.now }

    it 'is true if all fields match' do
      s1 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      s2 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      expect(s1).to eq(s2)
    end

    it 'is not if call_number differs' do
      s1 = Summary.new 'callnum1', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      s2 = Summary.new 'callnum2', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      expect(s1).to_not eq(s2)
    end

    it 'is not if message_id differs' do
      s1 = Summary.new 'callnum1', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      s2 = Summary.new 'callnum2', '2@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      expect(s1).to_not eq(s2)
    end

    it 'is not if from differs' do
      s1 = Summary.new 'callnumb', '1@example.com', 'user1@example.com', 'n_subject', now, 'blurb'
      s2 = Summary.new 'callnumb', '1@example.com', 'user2@example.com', 'n_subject', now, 'blurb'
      expect(s1).to_not eq(s2)
    end

    it 'is not if n_subject differs' do
      s1 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'ns 1', now, 'blurb'
      s2 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'ns 2', now, 'blurb'
      expect(s1).to_not eq(s2)
    end

    it 'is not if date differs' do
      s1 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now, 'blurb'
      s2 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now + 1, 'blurb'
      expect(s1).to_not eq(s2)
    end

    it 'is not if blurb differs' do
      s1 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now, 'b 1'
      s2 = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'n_subject', now, 'b 2'
      expect(s1).to_not eq(s2)
    end
  end
end

end # Chibrary
