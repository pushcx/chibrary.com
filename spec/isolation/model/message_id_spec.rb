require_relative '../../rspec'
require_relative '../../../model/message_id'

describe MessageId do
  describe '#valid?' do
    it 'is valid if well-formatted' do
      expect(MessageId.new('<valid@example.com>')).to be_valid
    end

    it 'is invalid if nil' do
      expect(MessageId.new nil).to_not be_valid
    end

    it 'is invalid if empty string' do
      expect(MessageId.new('')).to_not be_valid
    end

    it 'is invalid if longer than 120 characters' do
      str = ('x' * 109) + "@example.com"
      expect(MessageId.new str).to_not be_valid
    end

    it 'is invalid if it does not include an id' do
      expect(MessageId.new 'I like cats').to_not be_valid
    end
  end

  describe '#has_id?' do
    it 'does with and without angle brackets' do
      expect(MessageId.new '<with@example.com>').to have_id
      expect(MessageId.new 'without@example.com').to have_id
    end

    it 'does not with multiple @s' do
      expect(MessageId.new 'bad@heart@example.com').to_not have_id
    end

    it 'does not with no text before or after the @' do
      expect(MessageId.new 'bad@').to_not have_id
      expect(MessageId.new '@example.com').to_not have_id
    end
  end

  describe '#to_s' do
    it 'returns the extracted id' do
      expect(MessageId.new('<id@example.com>').to_s).to eq('id@example.com')
    end
    it 'does not pass invalid ids' do
      s = MessageId.new('cats are great').to_s
      expect(s).to_not include('cats')
      expect(s).to include('invalid')
    end
  end

  describe '#inspect' do
    it 'includes the #to_s' do
      expect(MessageId.new('id@example.com').inspect).to include('id@example.com')
      expect(MessageId.new('cats rule').inspect).to include('invalid')
    end
  end

  describe '#==' do
    it 'considers equal based on extracted id, not raw' do
      expect(MessageId.new('id@example.com')).to eq(MessageId.new('<id@example.com>'))
    end

    it 'coerces strings to MessageIds to test' do
      expect(MessageId.new('id@example.com')).to eq('id@example.com')
    end

    it 'does not consider invalid ids equal to themselves' do
      expect(MessageId.new('cat')).to_not eq(MessageId.new('cat'))
    end
  end

  describe '#hash' do
    it 'hashes consistently' do
      expect(MessageId.new('id@example.com').hash).to eq(MessageId.new('id@example.com').hash)
    end

    it 'uniqs' do
      # http://stackoverflow.com/questions/20388090/arrayuniq-ignoring-identical-hash-values
      a = [MessageId.new('id@example.com'), MessageId.new('id@example.com')]
      a.uniq!
      expect(a.length).to eq(1)
    end
  end

  describe '::generate_for' do
    it 'creates based on call number' do
      expect(MessageId.generate_for('0123456789').to_s).to include('0123456789')
    end

    it 'raises without a call_number' do
      expect {
        MessageId.generate_for ''
      }.to raise_error(ArgumentError)
    end
  end

  describe '::extract_or_generate' do
    it 'given a valid message id string, creates from that' do
      mid = MessageId.extract_or_generate('id@example.com', 'call')
      expect(mid.to_s).to include('id@example.com')
    end

    it 'given a valid message id object, creates from that' do
      mid = MessageId.extract_or_generate(MessageId.new('id@example.com'), 'call')
      expect(mid.to_s).to include('id@example.com')
    end


    it 'given an invalid message id, generates from call_number' do
      mid = MessageId.extract_or_generate('srsly cats man', 'call')
      expect(mid.to_s).to include('call')
    end
  end

  context 'real-world awful things' do
    it 'does not error on message_ids with Ruby string formatting' do
      expect(MessageId.new('<id%m%d%s@example.com>').to_s).to eq('id%m%d%s@example.com')
    end
  end
end
