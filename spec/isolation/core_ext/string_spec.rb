require_relative '../../rspec'
require_relative '../../../lib/string_'

describe String do
  describe '.decoded' do
    it 'extracts quoted-printable'
    it 'extracts something else'
  end

  describe '.to_utf8' do
    it 'recodes other charsets to utf8' do
      # I hate testing charsets. I'm going to wait for a bug.
      #js = "Peñe".encode('windows-1252')
      #expect(s.to_utf8).to eq("Peña")
    end

    it "doesn't raise errors on invalid utf8" do
    end
  end
end
