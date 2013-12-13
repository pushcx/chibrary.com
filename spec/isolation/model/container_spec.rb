require_relative '../../rspec'
require_relative '../../../model/container'

require 'permutation'

describe Container do
  describe '::new' do
    it 'is empty with just a message id' do
      c = Container.new 'id@example.com'
      expect(c).to be_empty
      expect(c).to be_orphan
      expect(c.children).to be_empty
    end

    it 'is not empty with a message' do
      c = Container.new(FakeMessage.new)
      expect(c).to_not be_empty
    end
  end

  describe '#==' do
    it 'considers empty containers with ids equal' do
      c1  = Container.new '1@example.com'
      c1_ = Container.new '1@example.com'
      c2  = Container.new '2@example.com'
      expect(c1).to eq(c1_)
      expect(c1).to_not eq(c2)
    end

    it 'considers containers with the same message equal' do
      c1  = Container.new FakeMessage.new('c1@example.com')
      c1_ = Container.new FakeMessage.new('c1@example.com')
      c2  = Container.new FakeMessage.new('c2@example.com')
      expect(c1).to eq(c1_)
      expect(c1).to_not eq(c2)
    end
  end

  describe '#count' do
    it 'does not count empty containers' do
      c = Container.new '1@example.com'
      expect(c.count).to eq(0)
    end

    it 'does count messages' do
      c = Container.new FakeMessage.new
      expect(c.count).to eq(1)
    end

    it 'counts multiple messages' do
      c1 = Container.new FakeMessage.new('c1@example.com')
      c2 = Container.new FakeMessage.new('c2@example.com')
      c1.adopt c2
      expect(c1.count).to eq(2)
    end

    it 'with some empty containers, does not count empties' do
      c1 = Container.new FakeMessage.new('c1@example.com')
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new FakeMessage.new('c3@example.com')
          c2.adopt c3
      expect(c1.count).to eq(2)
    end
  end

  describe "#depth" do
    it "is 0 for the root message" do
      c = Container.new 'c1@example.com'
      expect(c.depth).to eq(0)
    end

    it "is 1 for any child" do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
        c3 = Container.new 'c3@example.com'
        c1.adopt c3
      expect(c2.depth).to eq(1)
      expect(c3.depth).to eq(1)
    end

    it "is 2 for a grandchild" do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com'
          c2.adopt c3
      expect(c3.depth).to eq(2)
    end
  end

  describe '#empty?' do
    it 'considers a container without a message empty' do
      c = Container.new 'id@example.com'
      expect(c).to be_empty
    end
    it 'considers a container with a message not empty' do
      c = Container.new(FakeMessage.new)
      expect(c).to_not be_empty
    end
  end

  describe '#likely_split_thread?' do
    it 'considers an empty container likely split' do
      c = Container.new('c@example.com')
      expect(c).to be_likely_split_thread
    end

    it 'considers a message with a Re: subject likely split' do
      class FakeReplyMessage < FakeMessage
        def subject_is_reply? ; true ; end
      end

      c = Container.new FakeReplyMessage.new
      expect(c).to be_likely_split_thread
    end

    it 'considers a message with quoting likely split' do
      class FakeQuotingMessage < FakeMessage
        def subject_is_reply? ; false ; end
        def body ; "> foo\n\noh i totes agree" ; end
      end

      c = Container.new FakeQuotingMessage.new
      expect(c).to be_likely_split_thread
    end
  end

  describe '#to_s' do
    it 'identifies empty containers' do
      c = Container.new('c@example.com')
      expect(c.to_s).to include('empty')
    end

    it 'includes from and date with a message' do
      c = Container.new(FakeMessage.new('c@example.com'))
      expect(c.to_s).to include('c@example.com')
    end

    # this is pending because #empty? calls #message to lazy-load from db
    #it 'includes an id and key when it has them' do
    #  c = Container.new('c@example.com', 'key')
    #  expect(c.to_s).to include('c@example.com')
    #  expect(c.to_s).to include('key')
    #end
  end

  describe '#child_of?' do
    it 'considers children to be childs of their parents' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
      expect(c2).to be_a_child_of(c1)
    end

    it 'considers grandchildren to be childs of their grandparents' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com'
          c2.adopt c3
      expect(c3).to be_a_child_of(c1)
    end

    it 'does not consider parents to be childs of their children' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
      expect(c1).to_not be_a_child_of(c2)
    end
    
    it 'does not consider unrelated messages to be childs of each other' do
      c1 = Container.new 'c1@example.com'
      c2 = Container.new 'c2@example.com'
      expect(c1).to_not be_a_child_of(c2)
      expect(c2).to_not be_a_child_of(c1)
    end
  end

  describe '#root?' do
    it 'considers the top message to be the root' do
      c1 = Container.new FakeMessage.new('c1@example.com')
        c2 = Container.new FakeMessage.new('c2@example.com')
        c1.adopt c2
      expect(c1).to be_root
      expect(c2).to_not be_root
    end

    it 'considers empty containers to be the root' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new FakeMessage.new('c2@example.com')
        c1.adopt c2
      expect(c1).to be_root
      expect(c2).to_not be_root
    end

    it 'does not consider a child container to be the root' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
      expect(c2).to_not be_root
    end
  end

  describe '#root' do
    it 'finds the root message from any container' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com'
          c2.adopt c3
      expect(c1.root).to be(c1)
      expect(c2.root).to be(c1)
      expect(c3.root).to be(c1)
    end
  end

  describe '#each' do
    it 'iterates in reading order, an in-order traversal' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com'
          c2.adopt c3
        c4 = Container.new 'c4@example.com'
        c1.adopt c4

      seen = c1.collect { |c| c.message_id }.map { |s| s[0..1] }
      expect(seen).to eq(%w(c1 c2 c3 c4))
    end
  end

  describe '#effective_root' do
    it 'is a container with a message' do
      c1 = Container.new FakeMessage.new('c1@example.com')
        c2 = Container.new 'c1@example.com'
        c1.adopt c2
      expect(c1.effective_root).to be(c1)
    end

    it 'is an empty container with multiple children' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new FakeMessage.new('c2@example.com')
        c1.adopt c2
        c3 = Container.new FakeMessage.new('c2@example.com')
        c1.adopt c3
      expect(c1.effective_root).to be(c1)
    end

    it 'is not an empty container with one child' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new FakeMessage.new('c2@example.com')
        c1.adopt c2
      expect(c1.effective_root).not_to be(c1)
    end
  end

  describe '#effective_field' do
    it 'gets fields from the message' do
      c = Container.new FakeMessage.new('c@example.com')
      expect(c.effective_field(:message_id)).to eq('c@example.com')
    end

    it 'gets fields from the first non-blank message (in-order traversal)' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new FakeMessage.new('c3@example.com')
          c2.adopt c3
        c4 = Container.new FakeMessage.new('c4@example.com')
        c1.adopt c4
      expect(c1.effective_field(:message_id)).to eq('c3@example.com')
    end
  end

  describe '#slug' do
    it 'fetches the list slug' do
      c = Container.new FakeMessage.new('c@example.com')
      expect(c.slug).to eq('slug')
    end

    it 'falls back to empty string' do
      fm = FakeMessage.new('c@example.com')
      def fm.list ; nil ; end
      c = Container.new fm
      expect(c.slug).to eq('')
    end
  end

  describe '#orphan' do
    it 'breaks parent/child relationships' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2

      c2.orphan
      expect(c1.children).to be_empty
      expect(c2).to be_orphan
    end
  end

  describe '#disown' do
    it 'causes a parent to stop considering a conatiner its child' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2

      c1.send(:disown, c2)
      expect(c1.children).to be_empty
      # warning: disown is to be called only by orphan; c2 still thinks c1 is
      # its parent - the world is in an inconsistent state
    end
  end

  describe '#parent=' do
    it 'tells a child what its parent is' do
      c1 = Container.new 'c1@example.com'
      c2 = Container.new 'c2@example.com'
      c2.send(:parent=, c1)

      expect(c2.parent).to be(c1)
    end
  end

  describe '#message=' do
    it 'accepts messages to empty containers' do
      c = Container.new 'c@example.com'
      m = FakeMessage.new('c@example.com')
      c.message = m
      expect(c.message).to be(m)
    end

    it 'rejects messages if not empty' do
      c = Container.new FakeMessage.new('c@example.com')
      m = FakeMessage.new('c@example.com')
      expect {
        c.message = m
      }.to raise_error(/non-empty/)
    end

    it 'rejects messages with different ids' do
      c = Container.new 'container@example.com'
      m = FakeMessage.new('fake@example.com')
      expect {
        c.message = m
      }.to raise_error(/doesn't match/)
    end
  end

  describe '#adopt' do
    # Calls to adopt that would set up a cyclical graph should just be quietly
    # ignored. Because we're parenting based on references that are often
    # genereated incopetently, and can be generated maliciously, it's not an
    # exceptional circumstance the threader really cares to know about.
    it 'adopts containers' do
      c1 = Container.new 'c1@example.com'
      c2 = Container.new 'c2@example.com'
      expect(c1.children).to be_empty
      expect(c2).to be_orphan
      c1.adopt(c2)
      expect(c2.parent).to be(c1)
      expect(c2.root).to be(c1)
      expect(c1.children).to eq([c2])
      expect(c2).to_not be_orphan
    end

    it 'does not adopt itself' do
      c1 = Container.new 'c@example.com'
      c1.adopt c1
      expect(c1).to be_orphan
      expect(c1.children).to be_empty
    end

    it 'does not adopt its parent' do
      c1 = Container.new 'c1@example.com'
      c2 = Container.new 'c2@example.com'
      c1.adopt(c2)
      c2.adopt(c1)
      expect(c1).to be_root
      expect(c2.parent).to be(c1)
    end

    it 'does not adopt an already-parented container' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2

      other = Container.new 'other@example.com'
      other.adopt(c2)
      expect(c2.parent).to be(c1)
      expect(other.children).to be_empty
    end

    it 'trust a message about its parent when adopting' do
      class FakeAdoptMessage < FakeMessage
        def references ; ['c2@example.com'] ; end
      end
      c1 = Container.new FakeMessage.new('c1@example.com')
      c2 = Container.new FakeMessage.new('c2@example.com')
      c3 = Container.new FakeAdoptMessage.new('c3@example.com')
      c1.adopt c3
      c1.adopt c2
      c2.adopt c3
      expect(c3.parent).to eq(c2)
      expect(c1.children).to eq([c2])
      expect(c2.children).to eq([c3])
    end
  end

end
