require 'set'

require_relative '../rspec'
require_relative '../../value/sym'

module Chibrary

describe Sym do
  describe '#initialize' do
    it 'casts year to int' do
      expect(Sym.new('slug', '2014', 5).year).to eq(2014)
    end

    it 'casts month to int' do
      expect(Sym.new('slug', 2014, '5').month).to eq(5)
    end

    it 'interprets months with leading zeros decimally' do
      expect(Sym.new('slug', 2014, '09').month).to eq(9)
    end
  end

  describe '#same_time_as?' do
    it 'is if year and month match' do
      expect(Sym.new('slug', 2014, 9)).to be_same_time_as(Sym.new('slug', 2014, 9))
    end

    it 'is not if year or month differ' do
      expect(Sym.new('slug', 2014, 8)).to_not be_same_time_as(Sym.new('slug', 2014, 9))
      expect(Sym.new('slug', 2013, 9)).to_not be_same_time_as(Sym.new('slug', 2014, 9))
    end
  end

  describe '#plus_month' do
    it 'gives a sym for the given offset in months' do
      expect(Sym.new('slug', 2014, 9).plus_month(1)).to eq(Sym.new('slug', 2014, 10))
    end

    it 'can take negative months' do
      expect(Sym.new('slug', 2014, 9).plus_month(-1)).to eq(Sym.new('slug', 2014, 8))
    end

    it 'wraps years' do
      expect(Sym.new('slug', 2014, 9).plus_month(4)).to eq(Sym.new('slug', 2015, 1))
    end
  end

  describe '#to_key' do
    it 'is the slug, year, and two-digit month' do
      expect(Sym.new('slug', 2014, 5).to_key).to eq('slug/2014/05')
    end
  end

  describe '#to_sy' do
    it 'returns a Sy with same slug and year' do
      sym = Sym.new('slug', 2014, 5)
      sy = sym.to_sy
      expect(sym.slug).to eq(sy.slug)
      expect(sym.year).to eq(sy.year)
    end
  end

  describe 'in a set' do
    it 'does not duplicate' do
      sym1 = Sym.new('slug', 2014, 5)
      sym2 = Sym.new('slug', 2014, 5)
      set = Set.new [sym1, sym2]
      expect(set.size).to eq(1)
    end
  end

  describe '#==' do
    it 'is if slug, year, and month match' do
      expect(Sym.new('slug', 2014, 9)).to eq(Sym.new('slug', 2014, 9))
    end

    it 'is not if slug, year, or month differ' do
      expect(Sym.new('blah', 2014, 9)).to_not eq(Sym.new('slug', 2014, 9))
      expect(Sym.new('slug', 2013, 9)).to_not eq(Sym.new('slug', 2014, 9))
      expect(Sym.new('slug', 2014, 1)).to_not eq(Sym.new('slug', 2014, 9))
    end
  end
end

end # Chibrary
