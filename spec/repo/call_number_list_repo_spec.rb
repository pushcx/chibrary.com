require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../model/list'
require_relative '../../repo/call_number_list_repo'

describe CallNumberListRepo do
  context 'instantiated with a list of call numbers' do
    it '#extract_key' do
      cnls = CallNumberListRepo.new(Sym.new('slug', 2014, 1), ['callnum1', 'callnum2'])
      expect(cnls.extract_key).to eq('slug/2014/01')
    end

    it '#serialize' do
      cnls = CallNumberListRepo.new(Sym.new('slug', 2014, 1), ['callnum1', 'callnum2'])
      expect(cnls.serialize).to eq(['callnum1', 'callnum2'])
    end
  end

  it '#deserialize' do
    call_numbers = CallNumberListRepo.deserialize ['callnum1', 'callnum2']
    expect(call_numbers).to eq([CallNumber.new('callnum1'), CallNumber.new('callnum2')])
  end
end
