require_relative '../../rspec'
require_relative '../../../model/storage/summary_storage'
require_relative '../../../model/storage/summary_container_storage'

describe SummaryContainerStorage do
  describe '#value_to_hash' do
    FakeMessageContainer = Struct.new(:key, :value)

    it 'delegates to SummaryStorage' do
      summary = 'summary placeholder'
      c = FakeMessageContainer.new 'key', summary
      SummaryStorage.should_receive(:new).with(summary).and_return({})
      SummaryContainerStorage.new(c).value_to_hash
    end
  end

  describe '::value_from_hash' do
    it 'delegates to SummaryStorage' do
      hash = {}
      SummaryStorage.should_receive(:from_hash).with(hash)
      SummaryContainerStorage.value_from_hash(hash)
    end
  end
end
