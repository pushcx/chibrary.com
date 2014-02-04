require_relative '../../rspec'
require_relative '../../../model/thread_set'

require 'permutation'

ThreadableMessage = Struct.new(:message_id, :subject, :references) do
  def n_subject ; subject ; end
  def date ; Time.now ; end
  def likely_thread_creation_from?(email) ; false ; end
  def email ; 'email' ; end
end

describe ThreadSet do
  let(:ts) { ThreadSet.new 'slug', 2014, 1 }

#  it 'hashes thread subjects -> call number' do
#    c = Container.new
#    ts << Message
#    ts.finish
#    expect(ts.subjects).to eq({
#      '
#    })
#  end

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
      perm = Permutation.for(messages)
      previous = nil
      perm.each do |perm|
        ts = ThreadSet.new 'slug', 2009, 2
        perm.project.each { |message| ts << message }
        expect(ts).to eq(previous) if previous
        previous = ts
      end
    end
  end

  describe '#root_set' do
    it 'is empty with no threads' do
      expect(ts.send(:root_set)).to eq([])
    end

    it 'extracts a root set of threads' do
      ts << m1 = ThreadableMessage.new('m1@example.com', 'Foo', [])
        ts << m2 = ThreadableMessage.new('m2@example.com', 'Foo', ['m1@example.com'])
      ts << m3 = ThreadableMessage.new('m3@example.com', 'Foo', [])

      root_set = ts.send(:root_set)
      expect(root_set.length).to eq(2)
      expect(root_set.map(&:message)).to eq([m1, m3])
      expect(ts.send(:root_set)).to eq(root_set)
    end
  end
end
