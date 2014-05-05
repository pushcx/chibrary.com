require_relative '../../rspec'
require_relative '../../../repo/email_repo'

describe EmailRepo do
  describe '#serialize' do
    it 'saves fields' do
      email = Email.new({
        raw: "From: <alice@example.com>\n\nBody",
        from: 'bob@example.com',
      })
      hash = EmailRepo.new(email).serialize
      expect(hash[:from]).to eq('bob@example.com')
    end
  end

  describe '::deserialize' do
    it 'overrides raw data' do
      email = EmailRepo.deserialize({
        raw: "From: <alice@example.com>\n\nBody",
        from: 'bob@example.com',
      })
      expect(email.from).to eq('bob@example.com')
    end
  end
end
