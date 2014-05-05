require_relative '../../rspec'
require_relative '../../../model/list'
require_relative '../../../value/sym'
require_relative '../../../model/storage/call_number_list_storage'

describe CallNumberListStorage do
  context 'instantiated with a list of call numbers' do
    it '#extract_key' do
      cnls = CallNumberListStorage.new(Sym.new('slug', 2014, 1), ['callnumb01', 'callnumb02'])
      expect(cnls.extract_key).to eq('slug/2014/01')
    end

    it '#serialize' do
      cnls = CallNumberListStorage.new(Sym.new('slug', 2014, 1), ['callnumb01', 'callnumb02'])
      expect(cnls.serialize).to eq(['callnumb01', 'callnumb02'])
    end
  end

  it '#deserialize' do
    call_numbers = CallNumberListStorage.deserialize ['callnumb01', 'callnumb02']
    expect(call_numbers).to eq([CallNumber.new('callnumb01'), CallNumber.new('callnumb02')])
  end
end
