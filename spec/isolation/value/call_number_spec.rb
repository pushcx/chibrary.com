require_relative '../../rspec'
require_relative '../../../value/call_number'

describe CallNumber do
  describe '#initialize' do
    it 'can be initialized with a string' do
      expect(CallNumber.new('asdf12ASDF')).to be_valid
    end

    it 'can be initialized with a CallNumber' do
      expect(CallNumber.new(CallNumber.new('asdf12ASDF'))).to be_valid
    end
  end

  describe '#valid?' do
    it 'is with 10 alphanumberic characters' do
      expect(CallNumber.new('asdf12ASDF')).to be_valid
    end

    it 'is not if short' do
      expect(CallNumber.new('asdf12AS')).to_not be_valid
    end

    it 'is not if long' do
      expect(CallNumber.new('asdf12ASDF12')).to_not be_valid
    end

    it 'is not if containing other characters' do
      expect(CallNumber.new('asdf--ASDF')).to_not be_valid
      expect(CallNumber.new('asdf__ASDF')).to_not be_valid
      expect(CallNumber.new('asdf"aASDF')).to_not be_valid
    end
  end

  describe '#==' do
    it 'considers same strings equal' do
      expect(CallNumber.new('asdf12ASDF')).to eq(CallNumber.new('asdf12ASDF'))
    end

    it 'is case sensitive' do
      expect(CallNumber.new('asdf12asdf')).to_not eq(CallNumber.new('asdf12ASDF'))
    end
  end

  describe '#hash' do
    it 'hashes consistently' do
      expect(CallNumber.new('callnumber').hash).to eq(CallNumber.new('callnumber').hash)
    end

    it 'uniqs' do
      # http://stackoverflow.com/questions/20388090/arrayuniq-ignoring-identical-hash-values
      a = [CallNumber.new('callnumber'), CallNumber.new('callnumber')]
      a.uniq!
      expect(a.length).to eq(1)
    end
  end
end
