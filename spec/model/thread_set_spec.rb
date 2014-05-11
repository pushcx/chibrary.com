require 'more_math/permutation'

require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../model/message'
require_relative '../../model/thread_set'

ThreadableMessage = Struct.new(:message_id, :subject, :references) do
  def body ; '' ; end
  def n_subject ; subject ; end
  def date ; Time.now ; end
  def likely_thread_creation_from?(email) ; false ; end
  def email ; 'email' ; end
end

describe ThreadSet do
  let(:ts) { ThreadSet.new Sym.new('slug', 2014, 1) }

  describe '#==' do
    pending
  end

  describe '#<<' do
    let(:root)  { ThreadableMessage.new('root@example.com',  'Foo', []) }
    let(:child) { ThreadableMessage.new('child@example.com', 'Foo', ['root@example.com']) }

    it 'adds to containers' do
      ts << root
      expect(ts.containers.length).to eq(1)
    end

    it 'builds threads' do
      ts << root
      ts << child
      expect(ts.containers.count).to eq(2)
      threads = ts.collect { |c| c }
      expect(threads.count).to eq(1)
      expect(threads.first.message).to eq(root)
      expect(threads.first.children.first.message).to eq(child)
    end

    it 'can add messages to pre-created empty containers' do
      # same as previous spec with appends reversed
      ts << child
      ts << root
      expect(ts.containers.count).to eq(2)
      threads = ts.collect { |c| c }
      expect(threads.count).to eq(1)
      expect(threads.first.message).to eq(root)
      expect(threads.first.children.first.message).to eq(child)
    end

    it 'does not add a message twice' do
      ts << root
      ts << root
      expect(ts.containers.length).to eq(1)
    end

    it 'builds a consistent tree of messages' do
      # Whatever the order of messages from the example container_tree, the output should be the same.
      # Real-world messages can be ambiguous and order-dependent, but this is a basic structure test.
      messages = [
        ThreadableMessage.new('root@example.com', 'Foo', []),
          ThreadableMessage.new('child@example.com', 'Foo', ['root@example.com']),
            ThreadableMessage.new('grandchild@example.com', 'Foo', ['root@example.com', 'child@example.com']),
        ThreadableMessage.new('orphan@example.com', 'Foo', ['missing@example.com']),
      ]
      perm = MoreMath::Permutation.for(messages)
      previous = nil
      perm.each do |perm|
        ts = ThreadSet.new Sym.new('slug', 2009, 2)
        perm.project.each { |message| ts << message }
        expect(ts).to eq(previous) if previous
        previous = ts
      end
    end
  end

  describe '#threads' do
    it 'is empty with no threads' do
      expect(ts.send(:threads)).to eq([])
    end

    it 'extracts a root set of threads' do
      ts << m1 = ThreadableMessage.new('m1@example.com', 'Foo', [])
        ts << m2 = ThreadableMessage.new('m2@example.com', 'Foo', ['m1@example.com'])
      ts << m3 = ThreadableMessage.new('m3@example.com', 'Foo', [])

      threads = ts.send(:threads)
      expect(threads.length).to eq(2)
      expect(threads.map(&:message)).to eq([m1, m3])
      expect(ts.send(:threads)).to eq(threads)
    end
  end

  describe '#message_count' do
    it 'counts the messages' do
      ts << ThreadableMessage.new('m1@example.com', 'Foo', [])
        ts << ThreadableMessage.new('m2@example.com', 'Foo', ['m1@example.com'])
      ts << ThreadableMessage.new('orphan@example.com', 'Foo', ['missing@example.com'])
      expect(ts.message_count).to eq(3)
    end

    it 'can include number of empty containers' do
      ts << ThreadableMessage.new('orphan@example.com', 'Foo', ['missing@example.com'])
      expect(ts.message_count(true)).to eq(2)
    end
  end

  describe '#prior and following_months' do
    it 'gets syms for the following four months' do
      ts = ThreadSet.new Sym.new('slug', 2013, 11)
      expect(ts.following_months).to eq([
        Sym.new('slug', 2013, 12),
        Sym.new('slug', 2014,  1),
        Sym.new('slug', 2014,  2),
        Sym.new('slug', 2014,  3),
      ])
    end

    it 'gets syms for the prior four months' do
      ts = ThreadSet.new Sym.new('slug', 2013, 11)
      expect(ts.prior_months).to eq([
        Sym.new('slug', 2013, 10),
        Sym.new('slug', 2013,  9),
        Sym.new('slug', 2013,  8),
        Sym.new('slug', 2013,  7),
      ])
    end
  end

  context 'a complex, real-world set of threads' do
    let(:complex) { YAML::load_file('../fixture/complex_thread.yaml') }
    before do
      complex[:source_messages].each { |m| ts << Message.from_string(m, 'callnumber') }
      @found_thread_ids = ts.collect(&:message_id).map(&:to_s)
    end

    # need to hand-check these and uncomment
    xit 'has all threads in order' do
      expect(@found_thread_ids).to eq(complex[:thread_root_ids])
    end

    xit 'has all messages parented correctly' do
      parentings = {}
      ts.containers.each do |message_id, container|
        parentings[message_id.to_s] = container.parent && container.parent.message_id.to_s
      end
      expect(parentings).to eq(complex[:parentings])
    end
  end

  context 'threading based on quotes' do
    let(:fixture) { YAML::load_file('spec/fixture/quoting_reply.yaml') }

    it 'uses quotes in the absence of headers' do
      ts << (initial = Message.from_string(fixture[:initial_message], 'callnumber'))
      ts << (regular = Message.from_string(fixture[:regular_reply], 'callnumber'))
      ts << (quoting = Message.from_string(fixture[:quoting_reply], 'callnumber'))
      ts.send(:finish)
      expect(ts.containers[quoting.message_id].parent.message_id).to eq(regular.message_id)
    end
  end

  describe '#retrieve_split_threads_from' do
    let(:parent) { Message.from_string("Message-Id: parent@example.com\nSubject: Foo\n\nfoo", 'callnumber') }
    let(:child)  { Message.from_string("Message-Id: child@example.com\nSubject: Re: Foo\n\nfoo2", 'callnumber') }

    it 'threads an example - canary for retrieve_split_threads_from' do
      ts << parent
      ts << child
      ts.send(:finish)
      expect(ts.containers[MessageId.new('parent@example.com')].count).to eq(2)
    end

    it 'retrieves split threads from another threadset' do
      ts << parent
      other = ThreadSet.new Sym.new('slug', 2007, 12)
      other << child
      ts.send(:retrieve_split_threads_from, other)
      expect(other.containers.empty?)
      expect(ts.length).to eq(1)
      expect(ts.containers[MessageId.new('parent@example.com')].count).to eq(2)
    end

    it "does not retrieve split threads that don't reply to a thread in the set" do
      ts << parent
      other = ThreadSet.new Sym.new('slug', '2007', '12')
      # This message will be recognized as a split thread, but a parent for it
      # doesn't exist in ts
      other << Message.from_string("Message-Id: orphan@example.com\nIn-Reply-To: missing@example.com\nSubject: Bar\n\nbar", 'callnumber')
      ts.send(:retrieve_split_threads_from, other)
      expect(ts.length).to eq(1)
      expect(other.length).to eq(1)
    end
  end
end
