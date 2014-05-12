require_relative '../rspec'
require_relative '../../value/month_count'
require_relative '../../value/sym'

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

  describe '#empty?' do
    it 'is both counts are zero' do
      mc = MonthCount.new Sym.new('slug', 2014, 4), 0, 0
      expect(mc).to be_empty
    end

    it 'is not if either is above zero' do
      mc = MonthCount.new Sym.new('slug', 2014, 4), 1, 0
      expect(mc).to_not be_empty
      mc = MonthCount.new Sym.new('slug', 2014, 4), 0, 1
      expect(mc).to_not be_empty
    end
  end

  describe '#==' do
    it 'considers the same sym and counts to be equal' do
      sym = Sym.new('slug', 2014, 1)
      expect(MonthCount.new(sym, 1, 2)).to eq(MonthCount.new(sym, 1, 2))
    end

    it 'does not consider different sym to be the same' do
      expect(MonthCount.new(Sym.new('slug', 2014, 1), 1, 2)).not_to eq(MonthCount.new(Sym.new('DIFF', 2014, 1), 1, 2))
    end

    it 'does not consider different coutns to be the same' do
      sym = Sym.new('slug', 2014, 1)
      expect(MonthCount.new(sym, 1, 2)).not_to eq(MonthCount.new(sym, 1, 3))
      expect(MonthCount.new(sym, 1, 2)).not_to eq(MonthCount.new(sym, 2, 2))
    end
  end
end
