# encoding: UTF-8

require_relative '../../rspec'
require_relative '../../../lib/core_ext/string_'

describe String do
  describe '.decoded' do
    it 'extracts base64' do
      expect("=?utf-8?B?UGXDsWEsIEJvdHA=?= ".decoded).to eq("Peña, Botp ")
    end

    it 'extracts quoted-printable' do
      expect("=?utf-8?Q?Pe=C3=B1a?=".decoded).to eq("Peña")
    end
  end

  describe '.to_utf8' do
    it 'recodes other charsets to utf8' do
      s = "Peña".encode('windows-1252')
      expect(s.to_utf8 'windows-1252').to eq("Peña")
    end

    it "doesn't raise errors on invalid utf8" do
      # this sequence is invalid
      "\xc3\x28".to_utf8 'utf-8'
    end
  end
end
