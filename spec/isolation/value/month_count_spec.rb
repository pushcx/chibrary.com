require_relative '../../rspec'
require_relative '../../../value/month_count'

MCTestThreadSet = Struct.new(:sym, :thread_count, :message_count)

describe MonthCount do
  describe '::from' do
    it 'creates from a ThreadSet' do
      ts = MCTestThreadSet.new(Sym.new('slug', 2014, 4), 1, 2)
      mc = MonthCount.from ts
      expect(mc.thread_count).to eq(1)
      expect(mc.message_count).to eq(2)
    end
  end
end
