# encoding: UTF-8

require_relative '../rspec'
require_relative '../../value/email'
require_relative '../../repo/list_address_repo'

module Chibrary

describe Email do
  describe '::new' do
    it 'uses field-specific classes' do
      e = Email.new("Message-Id: id@example.com\nSubject: subject\n\nBody")
      expect(e.message_id).to be_a(MessageId)
      expect(e.subject).to be_a(Subject)
    end
  end

  describe 'subject delegation' do
    it '#subject returns subject object' do
      e = Email.new "Subject: Re: Foo\n\nBody"
      expect(e.subject).to eq(Subject.new('Re: Foo'))
    end

    it '#n_subject returns subject.normalized' do
      e = Email.new "Subject: Re: Foo\n\nBody"
      expect(e.n_subject).to eq('Foo')
    end
  end

  describe '#message_id' do
    it 'gets the header' do
      e = Email.new "Message-Id: id@example.com\n\nBody"
      expect(e.message_id).to eq('id@example.com')
    end
  end

  describe '#subject' do
    it 'gets the header' do
      e = Email.new "Subject: Foo\n\nBody"
      expect(e.subject).to eq('Foo')
    end
  end

  describe '#from' do
    it 'gets the header' do
      e = Email.new "From: alice@example.com\n\nBody"
      expect(e.from).to eq('alice@example.com')
    end

    it 'removes quote marks from around names' do
      [
        ['Bob <bob@example.com>',   'Bob <bob@example.com>'],
        ['"Bob" <bob@example.com>', 'Bob <bob@example.com>'],
      ].each do |original, cleaned|
        e = Email.new "From: #{original}\n\nBody"
        expect(e.from).to eq(cleaned)
      end
    end

    it 'decodes encoded Froms' do
      e = Email.new "From: =?utf-8?B?UGXDsWEsIEJvdHA=?= <botp@delmonte-phil.com>\n\nBody"
      expect(e.from).to eq('Peña, Botp <botp@delmonte-phil.com>')
    end
  end

  describe '#references' do
    it 'pulls from In-Reply-To and References' do
      e = Email.new "In-Reply-To: irt@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references).to include('irt@example.com')
      expect(e.references).to include('ref@example.com')
    end

    it 'puts In-Reply-To before References' do
      e = Email.new "In-Reply-To: irt@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references.index('irt@example.com')).to be < e.references.index('ref@example.com')
    end

    it 'maintains order of References' do
      e = Email.new "References: ref1@example.com ref2@example.com\n\nBody"
      expect(e.references.index('ref1@example.com')).to be < e.references.index('ref2@example.com')
    end

    it 'does not include duplicates' do
      e = Email.new "References: ref@example.com ref@example.com\n\nBody"
      expect(e.references.length).to eq(1)
      e = Email.new "In-Reply-To: ref@example.com\nReferences: ref@example.com\n\nBody"
      expect(e.references.length).to eq(1)
    end

    it 'ignores things that are not valid message ids' do
      e = Email.new "References: ref@example.com and cats\n\nBody"
      expect(e.references.join(' ')).to_not include('cats')
    end
  end

  describe '#date' do
    it 'extracts proper rfc2822 dates' do
      e = Email.new "Date: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e.date.to_s).to eq('2007-08-14 10:26:26 UTC')
    end

    it 'extracts dates to UTC' do
      e = Email.new "Date: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e.date.to_i).to eq(e.date.utc.to_i)
    end

    it 'extracts improper ISO dates, using the zone given' do
      e = Email.new "Date: 2007-08-07 16:06:33 -0400\n\nBody"
      expect(e.date.to_s).to eq('2007-08-07 20:06:33 UTC')
    end

    it 'extracts improper ISO dates, falling back to UTC' do
      e = Email.new "Date: 2007-08-07 16:06:33\n\nBody"
      expect(e.date.to_s).to eq('2007-08-07 16:06:33 UTC')
    end

    it 'falls back to the current time when all else fails' do
      e = Email.new "Date: cat o'clock\n\nBody"
      expect(e.date.to_i).to be_within(1).of(Time.now.utc.to_i)
    end

    it 'extracts from received headers first' do
      e = Email.new "Received: Tue, 05 May 2014 19:26:26 +0900\\nDate: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e.date.to_s).to eq('2014-05-05 10:26:26 UTC')
    end
  end

  describe '#no_archive?' do
    it "defaults false" do
      e = Email.new "\n\nBody"
      expect(e.no_archive?).to be_false
    end

    it "is true if X-No-Archive includes 'yes'" do
      e = Email.new "X-No-Archive: yes\n\nBody"
      expect(e.no_archive?).to be_true
    end

    it "is true if X-Archive has any text" do
      e = Email.new "X-Archive: cats\n\nBody"
      expect(e.no_archive?).to be_true
    end

    it "is true if Archive includes 'no'" do
      e = Email.new "Archive: no\n\nBody"
      expect(e.no_archive?).to be_true
    end
  end

  describe '#body' do
    it 'reads plain text messages' do
      e = Email.new "\n\nPlain text body."
      expect(e.body).to eq("Plain text body.")
    end

    it 'reads quoted-printable messages' do
      e = Email.new File.read('spec/fixture/email/quoted-printable.txt')
      expect(e.body).to include('in `lib/rubygems/package.rb´')
      expect(e.body).to_not include('=20')
    end

    it 'reads base64 encoded messages' do
      e = Email.new File.read('spec/fixture/email/base64.txt')
      expect(e.from).to include("Peña, Botp")
      expect(e.body).to include('put those in a batch file')
      expect(e.body).to_not include('RnJvbTogWXVzdWY')
    end

    it 'reads mime-encoded messages' do
      e = Email.new File.read('spec/fixture/email/mime-encoded.txt')
      expect(e.body).to include('the unix file command')
      expect(e.body).to_not include('Apple-Mail')
    end

    it 'reads messages with nested mime' do
      e = Email.new File.read('spec/fixture/email/nested-mime.txt')
      expect(e.body).to include('shoot their own')
      expect(e.body).to_not include('multipart')
    end

    it 'handles quoted-printable in mime' do
      e = Email.new File.read('spec/fixture/email/quoted-printable-in-mime.txt')
      expect(e.body.to_s).to_not eq('')
      expect(e.body).to include('Later Christoph')
      expect(e.body).to_not include('=20')
    end

    it 'ignores bad content types' do
      e = Email.new File.read('spec/fixture/email/bad-content-type.txt')
      expect(e.body.to_s).to_not eq('')
      expect(e.body).to include('just heuristics')
    end
  end

  describe '#canonicalized_from_email' do
    it 'is the from email address' do
      e = Email.new "From: Alice <alice@example.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@example.com')
    end

    it 'can get lightly spam-protected emails' do
      e = Email.new "From: Alice <alice at example.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@example.com')
    end

    it 'removes . from gmail addresses' do
      e = Email.new "From: Alice <ali.c.e@gmail.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@gmail.com')
    end

    it 'removes things right of a plus sign' do
      e = Email.new "From: Alice <alice+lists@example.com>\n\nBody"
      expect(e.canonicalized_from_email).to eq('alice@example.com')
    end

    it 'gives a stand-in for invaid emails' do
      e = Email.new "From: Alice \n\nBody"
      expect(e.canonicalized_from_email).to eq('no.email.address@chibrary.com')
    end
  end

  describe '#likely_thread_creation_from?' do
    def thread_creation_email from='from@example.com', subject='subject', body='Body'
      Email.new "From: #{from}\nSubject: #{subject}\n\n#{body}"
    end

    it 'is if someone replies to start a new thread' do
      p = thread_creation_email 'a@example.com', 'Subject', ''
      r = thread_creation_email 'b@example.com', 'Different', ''
      expect(r.likely_thread_creation_from? p).to be_true
    end

    it 'is not if a straightforward reply' do
      p = thread_creation_email 'a@example.com', 'Subject', ''
      r = thread_creation_email 'b@example.com', 'Re: Subject', ''
      expect(r.likely_thread_creation_from? p).to be_false
    end

    it 'is not if they quoted the parent' do
      p = thread_creation_email 'a@example.com', 'Foo', "a\nb"
      r = thread_creation_email 'b@example.com', 'Bar', "> a\n> b\nc"
      expect(r.likely_thread_creation_from? p).to be_false
    end

    it 'is if there are few words in common' do
      p = thread_creation_email 'a@example.com', 'Foo', "qwerty asdfgh zxcvbn wertyu sdfghj xcvbnm ertyui"
      r = thread_creation_email 'b@example.com', 'Bar', "text on a totally different topic"
      expect(r.likely_thread_creation_from? p).to be_true
    end

    it 'is not if there are many words in common' do
      p = thread_creation_email 'a@example.com', 'Foo', "qwerty asdfgh zxcvbn wertyu sdfghj xcvbnm ertyui"
      r = thread_creation_email 'b@example.com', 'Bar', "qwerty asdfgh zxcvbn wertyu sdfghj xcvbnm ertyui"
      expect(r.likely_thread_creation_from? p).to be_false
    end
  end

  describe '#possible_list_addresses' do
    it 'finds an address' do
      e = Email.new "X-Mailing-List: list@example.com\n\nBody"
      expect(e.possible_list_addresses).to eq(['list@example.com'])
    end

    it 'checks many headers to look up lists' do
      e = Email.new "X-Mailing-List: 1@example.com\nList-Id: 2@example.com\n\nBody"
      expect(e.possible_list_addresses).to eq(['1@example.com', '2@example.com'])
    end

    it 'always returns an array' do
      e = Email.new "\n\nBody"
      expect(e.possible_list_addresses).to be_a(Array)
    end
  end

  describe '#mid_hash' do
    it 'is nil if missing MessageId' do
      e = Email.new "\n\nBody"
      expect(e.mid_hash).to eq(nil)
    end

    it 'is stable based on MessageId' do
      e1 = Email.new "Message-Id: 1@example.com\n\nBody"
      e2 = Email.new "Message-Id: 1@example.com\n\nBody"
      expect(e1.mid_hash).to eq(e2.mid_hash)
    end

    it 'is sensitive to changes in MessageId' do
      e1 = Email.new "Message-Id: 1@example.com\n\nBody"
      e2 = Email.new "Message-Id: 2@example.com\n\nBody"
      expect(e1.mid_hash).not_to eq(e2.mid_hash)
    end
  end

  describe '#vitals_hash' do
    it 'is stable' do
      e1 = Email.new "Date: Tue, 14 Aug 2007 19:26:26 +0900\nFrom: user@example.com\nSubject: Foo\n\nBody"
      e2 = Email.new "Date: Tue, 14 Aug 2007 19:26:26 +0900\nFrom: user@example.com\nSubject: Foo\n\nBody"
      expect(e1.vitals_hash).to eq(e2.vitals_hash)
    end

    it 'is sensitive to changes in date' do
      e1 = Email.new "Date: Tue, 14 Aug 2007 19:26:26 +0900\n\nBody"
      e2 = Email.new "Date: Wed, 15 Aug 2007 19:26:26 +0900\n\nBody"
      expect(e1.vitals_hash).not_to eq(e2.vitals_hash)
    end

    it 'is sensitive to changes in from' do
      e1 = Email.new "From: alice@example.com\n\nBody"
      e2 = Email.new "From: bob@example.com\n\nBody"
      expect(e1.vitals_hash).not_to eq(e2.vitals_hash)
    end

    it 'is sensitive to changes in subject' do
      e1 = Email.new "Subject: Foo\n\nBody"
      e2 = Email.new "Subject: Bar\n\nBody"
      expect(e1.vitals_hash).not_to eq(e2.vitals_hash)
    end
  end

  describe '#==' do
    it 'considers same if raw text matches' do
      e1 = Email.new "From: foo\n\nBody"
      e2 = Email.new "From: foo\n\nBody"
      expect(e2).to eq(e1)
    end
  end

  describe '#direct_quotes' do
    it 'returns the contents of immediate quotes' do
      e = Email.new "\n\n> quote\nresponse"
      expect(e.direct_quotes).to include('quote')
    end

    it 'does not return direct text' do
      e = Email.new "\n\n> quote\nresponse"
      expect(e.direct_quotes).to_not include('response')
    end

    it 'does not return nested quotes' do
      e = Email.new "\n\n> > nested\n> quote\nresponse"
      expect(e.direct_quotes).to_not include('nested')
    end
  end

  describe '#lines_matching' do
    it 'counts the lines that match any of the lines given' do
      e = Email.new "\n\n> quote\nresponse"
      expect(e.lines_matching ['response']).to eq(1)
    end
  end
end

end # Chibrary
