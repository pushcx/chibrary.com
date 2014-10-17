require_relative '../rspec'
require_relative '../../value/message_id'
require_relative '../../value/thread_link'
require_relative '../../model/message'
require_relative '../../model/thread'

module Chibrary

describe Thread do
  let(:message) { Message.from_string "From: a@example.com\nDate: 2014-08-19 07:37:00\nSubject: a\n\nBody", 'callnumb', 'slug' }

  describe '::initialize' do
    it 'imports messages from Threads' do
      thread1 = Thread.new :slug, message
      thread2 = Thread.new :slug, thread1
      expect(thread2.count).to eq(1)
    end

    it 'imports messages from an array' do
      thread = Thread.new :slug, message
      expect(thread.count).to eq(1)
    end

    it 'requries one container' do
      expect {
        Thread.new :slug
      }.to raise_error(ArgumentError)
    end

    it 'errors if a block is given to catch collisions with built-in Thread' do
      expect {
        Thread.new(:slug, []) { |a| a }
      }.to raise_error(ArgumentError)
    end
  end

  describe '#sym' do
    it 'is based on the root message' do
      m = Message.from_string "Subject: a\nDate: 2014-08-19 07:40:00\n\nBody", 'callnumb', 'slug'
      thread = Thread.new :slug, m
      expect(thread.sym).to eq(Sym.new('slug', 2014, 8))
    end
  end

  describe 'sorting' do
    it 'is based on date only' do
      m1 = Message.from_string "Subject: a\nDate: 2014-08-20 07:40:00\n\nBody", 'callnumb', 'slug'
      m2 = Message.from_string "Subject: a\nDate: 2014-08-19 07:40:00\n\nBody", 'callnumb', 'slug'
      t1 = Thread.new :slug, m1
      t2 = Thread.new :slug, m2
      threads = [t1, t2]
      expect(threads.sort).to eq([t2, t1])
    end
  end

  describe '#call_numbers' do
    it 'returns call numbers' do
      m1 = Message.from_string "Subject: a\n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Subject: a\n\nBody", 'callnum2', 'slug'
      thread = Thread.new(:slug, m1)
      thread << m2
      expect(thread.call_numbers).to eq(['callnum1', 'callnum2'])
    end

    it 'does not return blanks or duplicates because of empty containers' do
      m = Message.from_string "Subject: a\nMessage-Id: b@example.com\nIn-Reply-To: a@example.com\n\nBody", 'callnumb', 'slug'
      thread = Thread.new(:slug, m)
      expect(thread.call_numbers).to eq(['callnumb'])
    end
  end

  describe '#message_count' do
    it 'ignores empty containers' do
      m = Message.from_string "Subject: a\nMessage-Id: b@example.com\nIn-Reply-To: a@example.com\n\nBody", 'callnumb', 'slug'
      thread = Thread.new :slug, m
      expect(thread.containers.count).to eq(2)
      expect(thread.message_count).to eq(1)
    end
  end

  describe '#message_ids' do
    it 'returns message_ids' do
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Message-Id: 2@example.com\n\nBody", 'callnum2', 'slug'
      thread = Thread.new :slug, m1
      thread << m2
      expect(thread.message_ids).to eq(['1@example.com', '2@example.com'])
    end

    it 'does include empty containers' do
      m = Message.from_string "Message-Id: 2@example.com\nIn-Reply-To: 1@example.com\n\nBody", 'callnum2', 'slug'
      thread = Thread.new :slug, m
      expect(thread.message_ids).to eq(['1@example.com', '2@example.com'])
    end
  end

  describe '#n_subjects' do
    it 'returns normalized subjects' do
      m1 = Message.from_string "Subject: Fwd: 1  \n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Subject: Re: 2\n\nBody", 'callnum2', 'slug'
      thread = Thread.new(:slug, m1)
      thread << m2
      expect(thread.n_subjects).to eq(['1', '2'])
    end

    it 'does not include duplicates' do
      m1 = Message.from_string "Subject: 1\n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Subject: 1\n\nBody", 'callnum2', 'slug'
      thread = Thread.new(:slug, m1)
      thread << m2
      expect(thread.n_subjects).to eq(['1'])
    end
  end

  describe '#conversation_for?' do
    let(:messages) { Hash[ YAML::load_file('spec/fixture/thread/conversation_for_middleware.yaml').map { |cn, raw| [cn, Message.from_string(raw, cn, 'slug')] } ] }

    it 'is if there is an empty container for it' do
      m1 = Message.from_string "Message-Id: 2@example.com\nIn-Reply-To: 1@example.com\n\nBody", 'callnum2', 'slug'
      thread = Thread.new :slug, m1
      m2 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum2', 'slug'
      expect(thread).to be_conversation_for(m2)
    end

    it 'is if subject matches' do
      m1 = Message.from_string "Subject: subj\n\nBody", 'callnum1', 'slug'
      thread = Thread.new(:slug, m1)
      m2 = Message.from_string "Subject: Re: subj\n\nBody", 'callnum2', 'slug'
      expect(thread).to be_conversation_for(m2)
    end

    it 'is if matching direct quotes' do
      m1 = Message.from_string "\n\nm1 text", 'callnum1', 'slug'
      thread = Thread.new(:slug, m1)
      m2 = Message.from_string "\n\n> m1 text\nm2", 'callnum2', 'slug'
      expect(thread).to be_conversation_for(m2)
    end

    it 'is if substantial quotes match, even with different subjects' do
      thread = Thread.new(:slug, messages[:ceo00001])
      thread << messages[:luca0001]
      expect(thread.conversation_for? messages[:michael1]).to be_true
    end
  end

  describe '#<<' do
    it 'stores Messages' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)

      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      thread << m1
      expect(thread.call_numbers).to include('callnum1')
    end

    it 'stores Containers' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)

      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      thread << Container.new(m1.message_id, m1)
      expect(thread.call_numbers).to include('callnum1')
    end

    it 'parents the message' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)

      m1 = Message.from_string "Message-Id: 1@example.com\nIn-Reply-To: 0@example.com\n\nBody", 'callnum1', 'slug'
      thread << m1
      expect(thread.containers[MessageId.new('1@example.com')].parent.message_id).to eq('0@example.com')
    end

    it 'may update the thread root' do
      m0 = Message.from_string "Subject: Re: foo\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)

      m1 = Message.from_string "Subject: foo\n\nBody", 'callnum1', 'slug'
      thread << m1
      expect(thread.root.call_number).to eq('callnum1')
    end

    it 'may make the message a parent' do
      m0 = Message.from_string "Subject: Re: foo\n\nBody", 'callnum1', 'slug'
      thread = Thread.new(:slug, m0)

      m1 = Message.from_string "Subject: foo\n\nBody", 'callnum0', 'slug'
      thread << m1
      expect(thread.root.call_number).to eq('callnum0')
      expect(thread.root.children.first.call_number).to eq('callnum1')
    end
  end

  describe '#store_in_container' do
    it 'creates containers' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      thread.send(:store_in_container, m1)
      expect(thread.containers.keys).to include('1@example.com')
    end

    it 'does not store duplicates, because Filer should have overlaid' do
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum2', 'slug'
      thread = Thread.new :slug, m1
      expect(thread.send(:store_in_container, m2).message).to be(m1)
    end

    it 'uses empty containers' do
      m0 = Message.from_string "Message-Id: 0@example.com\nIn-Reply-To: 1@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      c = thread.send(:store_in_container, m1)
      expect(c).to be_a(Container)
      expect(thread.containers.count).to eq(2)
    end
  end

  describe '#find_or_create_container' do
    it 'finds containers if existing' do
      m0 = Message.from_string "Message-Id: 0@example.com\nIn-Reply-To: 1@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)
      root = thread.root
      expect(root.key).to eq('1@example.com')
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      c = thread.send(:find_or_create_container, m1.message_id)
      expect(c).to be(root)
    end

    it 'creates containers if needed' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      m1 = Message.from_string "Message-Id: 1@example.com\n\nBody", 'callnum1', 'slug'
      thread = Thread.new(:slug, m0)
      expect {
        thread.send(:find_or_create_container, m1.message_id)
      }.to change { thread.containers.count }.by(1)
    end
  end

  describe '#create_root_reference_containers' do
    it 'sets the references given' do
      m2 = Message.from_string "Message-Id: 2@example.com\nIn-Reply-To: 1@example.com\nReferences: 0@example.com 1@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m2)
      expect(thread.root.message_id).to eq('0@example.com')
      expect(thread.root.children.first.message_id).to eq('1@example.com')
      expect(thread.root.children.first.children.first.message_id).to eq('2@example.com')
    end
  end

  describe '#set_root' do
    it 'takes the first container available' do
      m0 = Message.from_string "Message-Id: 0@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m0)
      expect(thread.root.message_id).to eq(m0.message_id)
    end

    it 'prefers an empty container to a full one' do
      m2 = Message.from_string "Message-Id: 2@example.com\nIn-Reply-To: 1@example.com\n\nBody", 'callnum0', 'slug'
      thread = Thread.new(:slug, m2)
      expect(thread.root.message_id).to eq('1@example.com')
    end

    it 'prefers messages with less re/fwd gunk' do
      m1 = Message.from_string "Subject: a\n\nBody", 'callnum1', 'slug'
      m2 = Message.from_string "Subject: Re: a\n\nBody", 'callnum2', 'slug'
      thread = Thread.new(:slug, m1)
      thread << m2
      expect(thread.root.call_number).to eq('callnum1')
    end
  end

  describe '#parent_messages_without_references' do
    it 'parents to the message with the most quotes' do
      m1 = Message.from_string "\n\nquoted text 1\nquoted text 2\nquoted text 3", 'callnum1', 'slug'
      m2 = Message.from_string "\n\nquoted text 1\nquoted text 2", 'callnum2', 'slug'
      m3 = Message.from_string "\n\n> quoted text 1\n> quoted text 2\n> quoted text 3\n\nm2", 'callnum3', 'slug'
      thread = Thread.new(:slug, m1)
      thread << m2
      thread << m3
      expect(thread.containers[MessageId.new 'callnum3@generated-message-id.chibrary.org'].parent.call_number).to eq('callnum1')
    end
  end

  describe '#safe_to_thread?' do
    # if all these tests blow up, it's probably because they're testing
    # Thread#safe_to_thread? with containers that aren't in its @containers
    it 'is if child is an orphan' do
      c1 = Container.new 'c1@example.com', message
      c2 = Container.new 'c2@example.com', message
      thread = Thread.new 'slug', c1
      expect(thread.send(:safe_to_thread?, c1, c2)).to be_true
    end

    it 'is not if child has a different parent' do
      m_possible_parent = Message.from_string "Message-Id: possible_parent@example.com\n\nBody", 'callnum0', 'slug'
      m_actual_parent = Message.from_string "Message-Id: actual_parent@example.com\nBody", 'callnum0', 'slug'
      m_child = Message.from_string "Message-Id: child@example.com\nIn-Reply-To: actual_parent@example.com\n\nBody", 'callnum0', 'slug'
      c_possible_parent = Container.new 'possible_parent@example.com', m_possible_parent
      c_actual_parent = Container.new 'actual_parent@example.com', m_actual_parent
      c_child = Container.new 'child@example.com', m_child
      c_actual_parent.adopt(c_child)
      thread = Thread.new 'slug', c_possible_parent
      expect(thread.send(:safe_to_thread?, c_possible_parent, c_child)).to be_false
    end

    it 'is if the child names this as their parent' do
      m_possible_parent = Message.from_string "Message-Id: possible_parent@example.com\n\nBody", 'callnum0', 'slug'
      m_actual_parent = Message.from_string "Message-Id: actual_parent@example.com\nBody", 'callnum0', 'slug'
      m_child = Message.from_string "Message-Id: child@example.com\nIn-Reply-To: actual_parent@example.com\n\nBody", 'callnum0', 'slug'
      c_possible_parent = Container.new 'possible_parent@example.com', m_possible_parent
      c_actual_parent = Container.new 'actual_parent@example.com', m_actual_parent
      c_child = Container.new 'child@example.com', m_child
      c_possible_parent.adopt(c_child)
      thread = Thread.new 'slug', c_possible_parent
      expect(thread.send(:safe_to_thread?, c_actual_parent, c_child)).to be_true
    end
  end

  describe "real world quoting" do
    let(:fixture) { YAML::load_file('spec/fixture/thread/quote_parenting_thread.yaml') }
    let(:parentings) { fixture[:parentings] }
    let(:raw_emails) { fixture[:raw_emails] }

    it "parents correctly" do
      root_cn, root_email = raw_emails.first
      raw_emails.delete root_cn
      root = Message.from_string(root_email, root_cn, 'slug')

      t = Thread.new 'slug', root
      raw_emails.each do |call_number, email|
        next unless parentings.keys.include? "#{call_number}@generated-message-id.chibrary.org"
        t << Message.from_string(email, call_number, 'slug')
      end

      parentings.each do |child, parent|
        c = t.containers[MessageId.new child]
        expect(c.parent.try(:message_id)).to eq(parent), "Child #{child} had wrong parent:"
      end

    end
  end

end

end
