require_relative '../../rspec'
require_relative '../../../model/storage/email_storage'

describe EmailStorage do
  describe '.to_hash' do
    it 'saves fields' do
      email = Email.new({
        raw: "From: <alice@example.com>\n\nBody",
        from: 'bob@example.com',
      })
      hash = EmailStorage.new(email).to_hash
      expect(hash[:from]).to eq('bob@example.com')
    end
  end

  describe '#from_hash' do
    it 'overrides raw data' do
      email = EmailStorage.from_hash({
        raw: "From: <alice@example.com>\n\nBody",
        from: 'bob@example.com',
      })
      expect(email.from).to eq('bob@example.com')
    end
  end
end
