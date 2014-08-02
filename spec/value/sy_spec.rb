require_relative '../rspec'
require_relative '../../value/sy'

module Chibrary

describe Sy do
  describe '#initialize' do
    it 'casts year to int' do
      expect(Sy.new('slug', '2014').year).to eq(2014)
    end
  end

  describe '#to_key' do
    it 'is the slug and year' do
      expect(Sy.new('slug', 2014).to_key).to eq('slug/2014')
    end
  end
end

end # Chibrary
