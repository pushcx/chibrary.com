require_relative '../../rspec'
require_relative '../../../model/message'
require_relative '../../../model/list'

describe Message do
  describe '#new' do
    it 'raises on invalid call_numbers' do
      expect {
        Message.new nil, 'foo'
      }.to raise_error(ArgumentError, /call_number/)
    end
  end

  describe '#from_string' do
    it 'creates emails' do
      m = Message.from_string 'email', 'callnumber'
      expect(m.email).to be_an(Email)
    end
  end

  describe '#from_message' do
    it 'copies fields' do
      m1 = Message.from_string "\n\nBody", 'callnumber', 'source', List.new('list')
      m2 = Message.from_message m1
      expect(m2.email.body).to eq(m1.email.body)
      expect(m2.call_number).to eq(m1.call_number)
      expect(m2.source).to eq(m2.source)
      expect(m2.list).to eq(m1.list)
    end
  end

  describe '.==' do
    it 'is the same if the fields are the same' do
      m1 = Message.from_string "\n\nBody", 'callnumber', 'source', List.new('list')
      m2 = Message.from_string "\n\nBody", 'callnumber', 'source', List.new('list')
      expect(m2).to eq(m1)
    end
  end
end
