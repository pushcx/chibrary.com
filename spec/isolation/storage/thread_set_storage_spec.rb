require_relative '../../rspec'
require_relative '../../../model/storage/thread_set_storage'

FakeTSContainer = Struct.new(:key, :message_id, :value, :children) do
end

describe ThreadSetStorage do
  context 'instantiated with a ThreadSet' do
    it 'stores summaries'
    it 'stores n/p links'
    it 'stores thread/message counts'
  end

  it 'loads a month of threads' do
    MessageContainerStorage.should_receive(:month).and_return([
      [FakeTSContainer.new('callnumbr1', '1@example.com', {}, [])],
      [FakeTSContainer.new('callnumbr2', '2@example.com', {}, [])],
    ])
    thread_set = ThreadSetStorage.month('slug', 2014, 1)
    expect(thread_set.containers.count).to eq(2)
  end
end
