require_relative '../rspec'
require_relative '../../value/call_number'

describe CallNumber do
  describe '#initialize' do
    it 'can be initialized with a string' do
      expect(CallNumber.new('asDF1234')).to be_valid
    end

    it 'can be initialized with a CallNumber' do
      expect(CallNumber.new(CallNumber.new('asDF1234'))).to be_valid
    end
  end

  describe '#valid?' do
    it 'is with exactly 8 alphanumberic characters' do
      expect(CallNumber.new('asdfASDF')).to be_valid
    end

    it 'is not if short' do
      expect(CallNumber.new('asdfASD')).to_not be_valid
    end

    it 'is not if long' do
      expect(CallNumber.new('asdfASDF1')).to_not be_valid
    end

    it 'is not if containing other characters' do
      expect(CallNumber.new('asdf--12')).to_not be_valid
      expect(CallNumber.new('asdf__12')).to_not be_valid
      expect(CallNumber.new('asdf"\'12')).to_not be_valid
    end
  end

  describe '#==' do
    it 'considers same strings equal' do
      expect(CallNumber.new('asdf12AS')).to eq(CallNumber.new('asdf12AS'))
    end

    it 'is case sensitive' do
      expect(CallNumber.new('asdf12as')).to_not eq(CallNumber.new('ASDF12AS'))
    end
  end

  describe '#hash' do
    it 'hashes consistently' do
      expect(CallNumber.new('callnumb').hash).to eq(CallNumber.new('callnumb').hash)
    end

    it 'uniqs' do
      # http://stackoverflow.com/questions/20388090/arrayuniq-ignoring-identical-hash-values
      a = [CallNumber.new('callnumb'), CallNumber.new('callnumb')]
      a.uniq!
      expect(a.length).to eq(1)
    end
  end
end
