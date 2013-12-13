# encoding: UTF-8

require_relative '../../rspec'
require_relative '../../../model/email'
require_relative '../../../model/storage/list_address_storage'

describe Email do
  describe '#new' do
    it 'prefers explicitly-set fields to extracted values' do
      e = Email.new({
        raw:  "From: raw@example.com\n\nBody",
        from: 'explicit@example.com',
      })
      expect(e.from).to eq('explicit@example.com')
    end

    it 'uses field-specific classes' do
      e = Email.new({
        raw:        "From: raw@example.com\n\nBody",
        message_id: 'explicit@example.com',
        subject:    'subject',
      })
      expect(e.instance_variable_get(:@message_id)).to be_a(MessageId)
      expect(e.instance_variable_get(:@subject)).to be_a(Subject)
    end
  end

  describe 'subject delegation' do
    it '.subject returns subject.to_s' do
      e = Email.new raw: '', subject: 'Re: Foo'
      expect(e.subject).to eq('Re: Foo')
    end

    it '.n_subject returns subject.normalized' do
      e = Email.new raw: '', subject: 'Re: Foo'
      expect(e.n_subject).to eq('Foo')
    end
  end

  describe '.extract_message_id' do
    it 'gets the header' do
      e = Email.new raw: "Message-Id: id@example.com\n\nBody"
      expect(e.message_id).to eq('id@example.com')
    end
  end

  describe '.extract_subject' do
    it 'gets the header' do
      e = Email.new raw: "Subject: Foo\n\nBody"
      expect(e.subject).to eq('Foo')
    end
  end

  describe '.extract_from' do
    it 'gets the header' do
      e = Email.new raw: "From: alice@example.com\n\nBody"
      expect(e.from).to eq('alice@example.com')
    end

    it 'removes quote marks from around names' do
      [
        ['Bob <bob@example.com>',   'Bob <bob@example.com>'],
        ['"Bob" <bob@example.com>', 'Bob <bob@example.com>'],
      ].each do |original, cleaned|
        e = Email.new raw: "From: #{original}\n\nBody"
        expect(e.from).to eq(cleaned)
      end
    end

    it 'decodes encoded Froms' do
      e = Email.new raw: "From: =?utf-8?B?UGXDsWEsIEJvdHA=?= <botp@delmonte-phil.com>\n\nBody"
      expect(e.from).to eq('Peña, Botp <botp@delmonte-phil.com>')
    end
  end

  describe '.extract_references' do
    it 'pulls from In-Reply-To and References' do
      e = Email.new raw: "In-Reply-To: irt@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references).to include('irt@example.com')
      expect(e.references).to include('ref@example.com')
    end

    it 'puts In-Reply-To before References' do
      e = Email.new raw: "In-Reply-To: irt@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references.index('irt@example.com')).to be < e.references.index('ref@example.com')
    end

    it 'maintains order of References' do
      e = Email.new raw: "References: ref1@example.com ref2@example.com\n\nBody"
      expect(e.references.index('ref1@example.com')).to be < e.references.index('ref2@example.com')
    end

    it 'does not include duplicates' do
      e = Email.new raw: "References: ref@example.com ref@example.com\n\nBody"
      expect(e.references.length).to eq(1)
      e = Email.new raw: "In-Reply-To: ref@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references.length).to eq(1)
    end

    it 'ignores things that are not valid message ids' do
      e = Email.new raw: "References: ref@example.com and cats\n\nBody"
      expect(e.references.join(' ')).to_not include('cats')
    end
  end

  describe '.extract_date' do
    it 'extracts proper rfc2822 dates' do
      e = Email.new raw: "Date: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e.date.to_s).to eq('2007-08-14 10:26:26 UTC')
    end

    it 'extracts dates to UTC' do
      e = Email.new raw: "Date: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e.date.to_i).to eq(e.date.utc.to_i)
    end

    it 'extracts improper ISO dates, using the zone given' do
      e = Email.new raw: "Date: 2007-08-07 16:06:33 -0400\n\nBody"
      expect(e.date.to_s).to eq('2007-08-07 20:06:33 UTC')
    end

    it 'extracts improper ISO dates, falling back to UTC' do
      e = Email.new raw: "Date: 2007-08-07 16:06:33\n\nBody"
      expect(e.date.to_s).to eq('2007-08-07 16:06:33 UTC')
    end

    it 'falls back to the current time when all else fails' do
      e = Email.new raw: "Date: cat o'clock\n\nBody"
      expect(e.date.to_i).to be_within(1).of(Time.now.utc.to_i)
    end
  end

  describe '.extract_no_archive' do
    it "defaults false" do
      e = Email.new raw: "\n\nBody"
      expect(e.no_archive).to be_false
    end

    it "is true if X-No-Archive includes 'yes'" do
      e = Email.new raw: "X-No-Archive: yes\n\nBody"
      expect(e.no_archive).to be_true
    end

    it "is true if X-Archive has any text" do
      e = Email.new raw: "X-Archive: cats\n\nBody"
      expect(e.no_archive).to be_true
    end

    it "is true if Archive includes 'no'" do
      e = Email.new raw: "Archive: no\n\nBody"
      expect(e.no_archive).to be_true
    end
  end

  describe ".extract_body" do
    it 'reads plain text messages' do
      e = Email.new raw: "\n\nPlain text body."
      expect(e.body).to eq("Plain text body.")
    end

    it 'reads quoted-printable messages' do
      e = Email.new raw: File.read('spec/fixture/email/quoted-printable.txt')
      expect(e.body).to include('in `lib/rubygems/package.rb´')
      expect(e.body).to_not include('=20')
    end

    it 'reads base64 encoded messages' do
      e = Email.new raw: File.read('spec/fixture/email/base64.txt')
      expect(e.from).to include("Peña, Botp")
      expect(e.body).to include('put those in a batch file')
      expect(e.body).to_not include('RnJvbTogWXVzdWY')
    end

    it 'reads mime-encoded messages' do
      e = Email.new raw: File.read('spec/fixture/email/mime-encoded.txt')
      expect(e.body).to include('the unix file command')
      expect(e.body).to_not include('Apple-Mail')
    end

    it 'reads messages with nested mime' do
      e = Email.new raw: File.read('spec/fixture/email/nested-mime.txt')
      expect(e.body).to include('shoot their own')
      expect(e.body).to_not include('multipart')
    end

    it 'handles quoted-printable in mime' do
      e = Email.new raw: File.read('spec/fixture/email/quoted-printable-in-mime.txt')
      expect(e.body.to_s).to_not eq('')
      expect(e.body).to include('Later Christoph')
      expect(e.body).to_not include('=20')
    end

    it 'ignores bad content types' do
      e = Email.new raw: File.read('spec/fixture/email/bad-content-type.txt')
      expect(e.body.to_s).to_not eq('')
      expect(e.body).to include('just heuristics')
    end
  end

  describe '.canonicalized_from_email' do
    it 'is the from email address' do
      e = Email.new raw: "From: Alice <alice@example.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@example.com')
    end

    it 'removes . from gmail addresses' do
      e = Email.new raw: "From: Alice <ali.c.e@gmail.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@gmail.com')
    end

    it 'removes things right of a plus sign' do
      e = Email.new raw: "From: Alice <alice+lists@example.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@example.com')
    end

    # what does it do with invalid/missing from addresses?
  end

  describe '.list' do
    it 'finds a list' do
      e = Email.new raw: "X-Mailing-List: list@example.com\n\nBody"
      ListAddressStorage.should_receive(:find_list_by_addresses).with(['list@example.com'])
      e.list
    end

    it 'checks many headers to look up lists' do
      e = Email.new raw: "X-Mailing-List: 1@example.com\nList-Id: 2@example.com\n\nBody"
      ListAddressStorage.should_receive(:find_list_by_addresses).with(['1@example.com', '2@example.com'])
      e.list
    end
  end

  describe '.==' do
    it 'considers same if fields and body match' do
      fields = {
        raw:        "\n\nBody",
        message_id: 'id@example.com',
        subject:    'Subject',
        from:       'From',
        references: ['ref@example.com'],
        date:       Time.now,
        no_archive: false,
      }
      e1 = Email.new fields
      e2 = Email.new fields
      expect(e2).to eq(e1)
    end

    it 'ignores raw headers differences with explicit fields' do
      e1 = Email.new raw: "Message-Id: raw1@example.com\n\nBody", message_id: 'id@example.com'
      e2 = Email.new raw: "Message-Id: raw2@example.com\n\nBody", message_id: 'id@example.com'
      expect(e2).to eq(e1)
    end
  end
end
