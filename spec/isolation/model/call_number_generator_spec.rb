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
      expect(spec_cng.format_ids_to_call(0, 99, 345)).to eq('D7Jo0CQ4')
    end
  end

  describe "#combine" do
    it "creates a string of bits" do
      expect(spec_cng.combine(0, 99, 345)).to eq('00000000000000000000000000110001100000101011001')
    end
  end

  describe "#stable_bitstring_shuffle" do
    it "shuffles bitstrings stably" do
      expect(spec_cng.stable_bitstring_shuffle('00000000000000000000000000110001100000101011001')).to eq('01010100000010000000100000110000000001010000000')
      expect(spec_cng.stable_bitstring_shuffle('00000000000000000000000000110001100000101011001')).to eq('01010100000010000000100000110000000001010000000')
    end

    it "depends on a seeded RNG that doesn't change" do
      cng = spec_cng
      expect(cng.stable_bitstring_shuffle('0123456789abcdefgh')).to eq('0d5164e2f98chgb7a3')
      expect(cng.stable_bitstring_shuffle('abcdefgh0123456789')).to eq('a5fbge6c7104983h2d')
      expect(cng.stable_bitstring_shuffle('asdfoihjaewnrfglka')).to eq('afishogdlearaknjwf')
      expect(cng.stable_bitstring_shuffle('984jtv43loiv8tnseo')).to eq('9tv84tn4sol8oev3ij')
    end
  end
end

