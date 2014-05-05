require_relative '../../rspec'
require_relative '../../../service/sequence_id_service'
require_relative '../../../service/call_number_service'

describe CallNumberService do
  describe "#consume_sequence_id!" do
    it "recognizes when a sequence is exhausted" do
      sig = double('SequenceIdService')
      calls = 0
      sig.stub(:consume_sequence_id!).and_return do
        calls += 1
        raise SequenceIdExhaustion if calls == 1
        raise RuntimeError if calls > 2
        0
      end
      sig.should_receive(:reset!)
      cng = CallNumberService.new CNGTestRunIdService.new, sig
      expect(cng.consume_sequence_id!).to eq(0)
    end
  end

  describe "#sequence_exhausted!" do
    it "advances run_id and resets sequence_id" do
      rig = RunIdService.new
      rig.should_receive(:next!)
      sig = SequenceIdService.new
      sig.should_receive(:reset!)
      cng = CallNumberService.new rig, sig
      cng.sequence_exhausted!
    end
  end
end
