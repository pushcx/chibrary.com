require_relative '../../rspec'
require_relative '../../../repo/thread_set_repo'

FakeTSContainer = Struct.new(:key, :message_id, :value, :children) do
end

describe ThreadSetRepo do
  context 'instantiated with a ThreadSet' do
    it 'stores summaries'
    it 'stores n/p links'
    it 'stores thread/message counts'
  end

  it 'loads a month of threads' do
    MessageContainerRepo.should_receive(:month).and_return([
      [FakeTSContainer.new('callnumbr1', '1@example.com', {}, [])],
      [FakeTSContainer.new('callnumbr2', '2@example.com', {}, [])],
    ])
    thread_set = ThreadSetRepo.month(Sym.new('slug', 2014, 1))
    expect(thread_set.containers.count).to eq(2)
  end
end
