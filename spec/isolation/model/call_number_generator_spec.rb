require_relative '../../rspec'
require_relative '../../../model/call_number_generator'

describe CallNumberGenerator do
  def spec_cng
    CallNumberGenerator.new CNGTestRunIdGenerator.new, CNGTestSequenceIdGenerator.new
  end

  describe "#next!" do
    it "combines IDS" do
      cng = spec_cng
      cng.should_receive(:format_ids_to_call).with(0, 1, 2)
      cng.next!
    end
  end

  describe "#version" do
    it "doesn't change without someone thinking about this" do
      expect(spec_cng.version).to eq(0)
    end
  end

  describe "#consume_sequence_id!" do
    it "consumes a sequence id" do
      sig = double('SequenceIdGenerator')
      sig.should_receive(:consume_sequence_id!).and_return(3)
      cng = CallNumberGenerator.new CNGTestRunIdGenerator.new, sig
      expect(cng.consume_sequence_id!).to eq(3)
    end

  end

  describe "#format_ids_to_call" do
    it "combines and shuffles ids" do
      expect(spec_cng.format_ids_to_call(0, 99, 345)).to eq('2VznWE2i')
    end
  end

  describe "#combine" do
    it "creates a string of bits" do
      expect(spec_cng.combine(0, 99, 345)).to eq('00000000000000000000000000110001100000101011001')
    end
  end

  describe "#stable_bitstring_shuffle" do
    it "shuffles bitstrings stably" do
      expect(spec_cng.stable_bitstring_shuffle('00000000000000000000000000110001100000101011001')).to eq('00010000000111100001000000010010000000000010000')
    end

    it "depends on a seeded RNG that doesn't change" do
      cng = spec_cng
      expect(cng.stable_bitstring_shuffle('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJK')).to eq('Ffkq6pn0g3iKGwvy1c7Cxo2aeB5Hdtrzl8I49uAjDJEhmbs')
    end
  end

  describe 'SHUFFLE_TABLE' do
    it 'does not change' do
      # While this looks like an awful test, it's vital to ensure call number
      # generation doesn't change - if it had a different shuffle order to
      # bits, it would start generating duplicate CallNumbers.
      # As far as I can imagine now, it's straightforward to increase
      # CALL_NUMBER_BITS, just make sure the new SHUFFLE_TABLE is the right
      # length. Nothing else needs to be changed because a longer call number
      # will never dupe a shorter one.
      expect(CALL_NUMBER_BITS).to eq(47)
      expect(CallNumberGenerator::SHUFFLE_TABLE).to eq([41, 15, 20, 26, 6, 25, 23, 0, 16, 3, 18, 46, 42, 32, 31, 34, 1, 12, 7, 38, 33, 24, 2, 10, 14, 37, 5, 43, 13, 29, 27, 35, 21, 8, 44, 4, 9, 30, 36, 19, 39, 45, 40, 17, 22, 11, 28])
    end
  end
end

