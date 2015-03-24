require_relative '../rspec'
require_relative '../../entity/message'

module Chibrary

describe Message do
  describe "overlaying email fields" do
    it "passes through to email by default" do
      m = Message.from_string "Subject: Foo\n\nBody", 'callnumb', 'slug'
      expect(m.subject).to eq('Foo')
    end

    it "can overlay email fields at initialization" do
      m = Message.from_string "Subject: Foo\n\nBody", 'callnumb', 'slug', 'source', subject: 'Bar'
      expect(m.subject).to eq('Bar')
    end

    it "can overlay email fields at runtime" do
      m = Message.from_string "Subject: Foo\n\nBody", 'callnumb', 'slug'
      m.subject = 'Bar'
      expect(m.subject).to eq('Bar')
    end

    it "can overlay n_subject from subject" do
      m = Message.from_string "Subject: Foo\n\nBody", 'callnumb', 'slug'
      m.subject = 'Bar'
      expect(m.n_subject).to eq('Bar')
    end

    it "generates message_id overlay if email is missing one" do
      m = Message.from_string "\n\nBody", 'callnumb', 'slug'
      expect(m.message_id.to_s).to include('callnumb')
    end
  end

  describe "blurb" do
    it "takes text from body" do
      m = Message.from_string "\n\nBody text", 'callnumb', 'slug'
      expect(m.blurb).to include('Body text')
    end

    it "ignores quotes" do
      m = Message.from_string "\n\nBody text\n> quoted\n\nnot quote", 'callnumb', 'slug'
      expect(m.blurb).to_not include('quoted')
    end

    it "skips blank lines" do
      m = Message.from_string "\n\nBody text\n\n\nnot quote", 'callnumb', 'slug'
      expect(m.blurb).to_not include("\n\n")
    end


    it "returns a max of 150 chars" do
      m = Message.from_string "\n\nIt would be cute if message blurbs fit in a tweet, but it turns out with narrow letters and short subjects that a thread_list item might need a few more characters", 'callnumb', 'slug'
      expect(m.blurb.length).to be <= 150
    end
  end

  describe '#likely_split_thread?' do
    it "is if subject is reply" do
      m = Message.from_string "Subject: Re: foo\n\n", 'callnumb', 'slug'
      expect(m.likely_split_thread?).to be_true
    end

    it "is if body quotes" do
      m = Message.from_string "\n\n> body\ntext", 'callnumb', 'slug'
      expect(m.likely_split_thread?).to be_true
    end
  end

  describe '#body_quotes?' do
    it 'does when there are quoted lines' do
      m = Message.from_string "\n\n> body\ntext", 'callnumb', 'slug'
      expect(m.body_quotes?).to be_true
    end

    it 'does not when there are no quoted liens' do
      m = Message.from_string "\n\nbody\ntext", 'callnumb', 'slug'
      expect(m.body_quotes?).to be_false
    end
  end

  describe '#==' do
    it 'is the same if the fields are the same' do
      m1 = Message.from_string "Message-Id: id@example.com\n\nBody", 'callnumb', 'slug', 'source', {}
      m2 = Message.from_string "Message-Id: id@example.com\n\nBody", 'callnumb', 'slug', 'source', {}
      expect(m2).to eq(m1)
    end
  end

  describe '::from_string' do
    it 'creates emails' do
      m = Message.from_string 'email', 'callnumb', 'slug'
      expect(m.email).to be_an(Email)
    end
  end

  describe '::from_message' do
    it 'copies fields' do
      m1 = Message.from_string "\n\nBody", 'callnumb', 'source'
      m2 = Message.from_message m1
      expect(m2.email.body).to eq(m1.email.body)
      expect(m2.call_number).to eq(m1.call_number)
      expect(m2.source).to eq(m2.source)
    end
  end
end

end # Chibrary
