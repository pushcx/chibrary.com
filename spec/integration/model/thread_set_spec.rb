require_relative '../../rspec'
require_relative '../../../model/sym'
require_relative '../../../model/thread_set'
require_relative '../../../model/message'

describe ThreadSet do
  let(:ts) { ThreadSet.new Sym.new('slug', 2014, 1) }

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
    let(:complex) { YAML::load_file( File.join(File.dirname(__FILE__), '..', '..', 'fixture', "complex_thread.yaml") ) }
    before do
      complex[:source_messages].each { |m| ts << Message.from_string(m, 'callnumber') }
      @found_thread_ids = ts.collect(&:message_id).map(&:to_s)
    end

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
    let(:fixture) { YAML::load_file( File.join(File.dirname(__FILE__), '..', '..', 'fixture', "quoting_reply.yaml") ) }

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
