require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../value/month_count'
require_relative '../../value/time_sort'
require_relative '../../repo/month_count_repo'
require_relative '../../repo/thread_set_repo'
require_relative '../../repo/time_sort_repo'

FakeTSContainer = Struct.new(:key, :message_id, :value, :children) do
end

describe ThreadSetRepo do
  describe '#store' do
    it 'delegates like mad' do
      sym = Sym.new('slug', 2014, 1)
      thread_set = ThreadSet.new(sym)
      mcr = double(MonthCountRepo, store: true)
      MonthCountRepo.should_receive(:new).with(MonthCount.from(thread_set)).and_return(mcr)
      tsr = double(TimeSortRepo, store: true)
      TimeSortRepo.should_receive(:new).with(TimeSort.from(thread_set)).and_return(tsr)
      ThreadSetRepo.new(thread_set).store
    end
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
