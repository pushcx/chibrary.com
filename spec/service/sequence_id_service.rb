require_relative '../rspec'
require_relative '../../service/sequence_id_service'

# This spec digs into the private instance variable @sequence_id to test
# thoroughly. A major feature of SequenceIdService is maintaining an API
# that prevents accidental reuse, so that is correctly private.
class TestSequenceIdService < SequenceIdService
  attr_accessor :sequence_id 
end

describe SequenceIdService do
  let(:sis) { TestSequenceIdService.new }

  describe '#initialize' do
    it 'starts at 0' do
      expect(sis.sequence_id).to eq(0)
    end

    it 'gives 0 for first consume' do
      expect(sis.consume_sequence_id!).to eq(0)
    end
  end

  describe '#reset!' do
    it 'returns to 0' do
      sis.sequence_id = 1000
      expect(sis.consume_sequence_id!).to eq(1000)
      sis.reset!
      expect(sis.consume_sequence_id!).to eq(0)
    end
  end

  describe '#consume_sequence_id!' do
    describe "query aspect" do
      it 'returns consecutive integers' do
        sis.sequence_id = rand(3000)
        a = sis.consume_sequence_id!
        b = sis.consume_sequence_id!
        expect(b - 1).to eq(a)
      end

      it 'can return the max sequence id' do
        sis.sequence_id = SequenceIdService::MAX_SEQUENCE_ID
        expect(sis.consume_sequence_id!).to eq(SequenceIdService::MAX_SEQUENCE_ID )
      end

      it 'will not return above the max sequence id' do
        sis.sequence_id = SequenceIdService::MAX_SEQUENCE_ID
        expect(sis.consume_sequence_id!).to eq(SequenceIdService::MAX_SEQUENCE_ID )
        expect {
          sis.consume_sequence_id!
        }.to raise_error(SequenceIdExhaustion)
      end
    end

    describe "command aspect" do
      it 'updates sequence_id' do
        sis.sequence_id = 1000
        sis.consume_sequence_id!
        expect(sis.sequence_id).to eq(1001)
      end
    end
  end
end

