require_relative '../rspec'
require_relative '../../repo/summary_repo'
require_relative '../../repo/summary_container_repo'

describe SummaryContainerRepo do
  describe '#serialize_value' do
    FakeMessageContainer = Struct.new(:key, :value)

    it 'delegates to SummaryRepo' do
      summary = 'summary placeholder'
      c = FakeMessageContainer.new 'key', summary
      SummaryRepo.should_receive(:new).with(summary).and_return(double('MessageRepo', serialize: {}))
      SummaryContainerRepo.new(c).serialize_value
    end
  end

  describe '::deserialize_value' do
    it 'delegates to SummaryRepo' do
      hash = {}
      SummaryRepo.should_receive(:deserialize).with(hash)
      SummaryContainerRepo.deserialize_value(hash)
    end
  end
end
