require_relative '../../rspec'
require_relative '../../../value/headers'

describe Headers do
  describe "#[]" do
    it 'looks up headers' do
      h = Headers.new "A: one\nB: two\nC: three"
      expect(h['B']).to eq('two')
    end

    it 'returns empty string for missing headers' do
      h = Headers.new "A: one"
      expect(h['B']).to eq('')
    end

    it 'returns the first match in case of duplicates' do
      h = Headers.new "A: one\nB: two\nA: three"
      expect(h['A']).to eq('one')
    end
  end

  describe '#all' do
    it 'returns an array in case of duplicates' do
      h = Headers.new "A: one\nB: two\nA: three"
      expect(h.all('A')).to eq(['one', 'three'])
    end

    it 'returns empty array in case nothing is found' do
      h = Headers.new "A: one\nB: two"
      expect(h.all('C')).to eq([])
    end
  end
end
