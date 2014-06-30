require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../repo/sym_repo'

describe SymRepo do
  context 'instantiated with a Sym' do
    describe '#serialize' do
      it 'is a string' do
        sym = Sym.new 'slug', 2014, 6
        expect(SymRepo.new(sym).serialize).to eq('slug/2014/06')
      end
    end
  end

  describe '::deserialize' do
    it 'works on a string' do
      sym = Sym.new 'slug', 2014, 6
      expect(SymRepo.deserialize('slug/2014/06')).to eq(sym)
    end
  end
end
