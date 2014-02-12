require_relative '../../rspec'
require_relative '../../../model/storage/summary_storage'
require_relative '../../../model/storage/summary_container_storage'

describe SummaryContainerStorage do
  describe '#serialize_value' do
    FakeMessageContainer = Struct.new(:key, :value)

    it 'delegates to SummaryStorage' do
      summary = 'summary placeholder'
      c = FakeMessageContainer.new 'key', summary
      SummaryStorage.should_receive(:new).with(summary).and_return(double('MessageStorage', serialize: {}))
      SummaryContainerStorage.new(c).serialize_value
    end
  end

  describe '::deserialize_value' do
    it 'delegates to SummaryStorage' do
      hash = {}
      SummaryStorage.should_receive(:deserialize).with(hash)
      SummaryContainerStorage.deserialize_value(hash)
    end
  end
end
