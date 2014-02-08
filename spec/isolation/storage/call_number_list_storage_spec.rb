require_relative '../../rspec'
require_relative '../../../model/list'
require_relative '../../../model/storage/call_number_list_storage'

describe CallNumberListStorage do
  context 'instantiated with a list of call numbers' do
    it '#extract_key' do
      cnls = CallNumberListStorage.new(List.new('slug'), 2014, 1, ['callnumb01', 'callnumb02'])
      expect(cnls.extract_key).to eq('slug/2014/01')
    end

    it '#to_hash' do
      cnls = CallNumberListStorage.new(List.new('slug'), 2014, 1, ['callnumb01', 'callnumb02'])
      expect(cnls.to_hash).to eq(['callnumb01', 'callnumb02'])
    end
  end

  it '#from_hash' do
    call_numbers = CallNumberListStorage.from_hash ['callnumb01', 'callnumb02']
    expect(call_numbers).to eq([CallNumber.new('callnumb01'), CallNumber.new('callnumb02')])
  end
end
