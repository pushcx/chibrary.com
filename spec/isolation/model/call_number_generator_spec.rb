require_relative '../../rspec'
require_relative '../../../model/call_number_generator'

describe CallNumberGenerator do
  describe '::to_base_62' do
    it 'converts integers to base 62' do
      [
        [0,  '0000000000'], # base case
        [1,  '0000000001'], # add one
        [10, '000000000a'], # first lowercase letter
        [36, '000000000A'], # first uppercase letter
        [62, '0000000010'], # second digit
        [63, '0000000011'], # second digit + 1
        [62 ** 10 - 1, 'ZZZZZZZZZZ'], # last number
      ].each do |from, to|
        expect(CallNumberGenerator.to_base_62 from).to eq(to)
      end
    end

    it 'does not convert negative numbers' do
      expect {
        CallNumberGenerator.to_base_62 -1
      }.to raise_error(RuntimeError, /No negative numbers/)
    end
    it 'does not convert numbers too large for call numbers' do
      expect {
        CallNumberGenerator.to_base_62 62 ** 10
      }.to raise_error(RuntimeError, /Too-large int converted/)
    end
  end
end
