require_relative '../../rspec'
require_relative '../../isolation/model/call_number_generator_spec'
require_relative '../../../model/sequence_id_generator'
require_relative '../../../model/call_number_generator'

describe CallNumberGenerator do
  describe "#consume_sequence_id!" do
    it "recognizes when a sequence is exhausted" do
      sig = double('SequenceIdGenerator')
      calls = 0
      sig.stub(:consume_sequence_id!).and_return do
        calls += 1
        raise SequenceIdExhaustion if calls == 1
        raise RuntimeError if calls > 2
        0
      end
      sig.should_receive(:reset!)
      cng = CallNumberGenerator.new CNGTestRunIdGenerator.new, sig
      expect(cng.consume_sequence_id!).to eq(0)
    end
  end

  describe "#sequence_exhausted!" do
    it "advances run_id and resets sequence_id" do
      rig = RunIdGenerator.new
      rig.should_receive(:next!)
      sig = SequenceIdGenerator.new
      sig.should_receive(:reset!)
      cng = CallNumberGenerator.new rig, sig
      cng.sequence_exhausted!
    end
  end
end
