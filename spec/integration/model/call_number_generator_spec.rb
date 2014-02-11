require_relative '../../rspec'
require_relative '../../../model/call_number_generator'

describe CallNumberGenerator do
  describe '::redis_next_call_number!' do
    it 'gets the next call number'
    it 'does not duplicate call number on concurrent request'
  end
end
