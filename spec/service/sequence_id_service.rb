require_relative '../rspec'
require_relative '../../service/sequence_id_service'

# This spec digs into the private instance variable @sequence_id to test
# thoroughly. A major feature of SequenceIdService is maintaining an API
# that prevents accidental reuse, so that is not changing from private.

class TestSequenceIdService < SequenceIdService
  attr_accessor :sequence_id 
end

describe SequenceIdService do
  describe '#initialize' do
    it 'starts at 0' do
      expect(TestSequenceIdService.new.sequence_id).to eq(0)
    end

    it 'gives 0 for first consume' do
      expect(TestSequenceIdService.new.consume_sequence_id!).to eq(0)
    end
  end

  describe '#reset!' do
    it 'returns to 0' do
      sig = TestSequenceIdService.new
      sig.sequence_id = 1000
      expect(sig.consume_sequence_id!).to eq(1000)
      sig.reset!
      expect(sig.consume_sequence_id!).to eq(0)
    end
  end

  describe '#consume_sequence_id!' do
    it 'updates sequence_id' do
      sig = TestSequenceIdService.new
      sig.sequence_id = 1000
      sig.consume_sequence_id!
      expect(sig.sequence_id).to eq(1001)
    end

    it 'returns consecutive integers' do
      sig = TestSequenceIdService.new
      sig.sequence_id = rand(3000)
      a = sig.consume_sequence_id!
      b = sig.consume_sequence_id!
      expect(b - 1).to eq(a)
    end

    it 'can return the max sequence id' do
      sig = TestSequenceIdService.new
      sig.sequence_id = SequenceIdService::MAX_SEQUENCE_ID 
      expect(sig.consume_sequence_id!).to eq(SequenceIdService::MAX_SEQUENCE_ID )
    end

    it 'will not return above the max sequence id' do
      sig = TestSequenceIdService.new
      sig.sequence_id = SequenceIdService::MAX_SEQUENCE_ID
      expect(sig.consume_sequence_id!).to eq(SequenceIdService::MAX_SEQUENCE_ID )
      expect {
        sig.consume_sequence_id!
      }.to raise_error(SequenceIdExhaustion)
    end
  end
end

