require_relative '../rspec'
require_relative '../../lib/container'

class TContainer
  include Container
end

class TValue
  attr_reader :field

  def initialize field=nil
    @field = field
  end
end

describe TContainer do
  describe '::new' do
    it 'is empty with just a key' do
      c = TContainer.new 'id@example.com'
      expect(c).to be_empty
      expect(c).to be_orphan
      expect(c.children).to be_empty
    end

    it 'is not empty with a value' do
      c = TContainer.new('id@example.com', TValue.new)
      expect(c).to_not be_empty
    end
  end

  describe '#==' do
    it 'considers empty containers with ids equal' do
      c1  = TContainer.new '1@example.com'
      c1_ = TContainer.new '1@example.com'
      c2  = TContainer.new '2@example.com'
      expect(c1).to eq(c1_)
      expect(c1).to_not eq(c2)
    end

    it 'considers containers with the same key equal, ignoring value diffs' do
      c1  = TContainer.new 'c1@example.com', TValue.new
      c1_ = TContainer.new 'c1@example.com', TValue.new
      c2  = TContainer.new 'c2@example.com', TValue.new
      expect(c1).to eq(c1_)
      expect(c1).to_not eq(c2)
    end
  end

  describe '#count' do
    it 'does not count empty containers' do
      c = TContainer.new '1@example.com'
      expect(c.count).to eq(0)
    end

    it 'does count values' do
      c = TContainer.new '1@example.com', TValue.new
      expect(c.count).to eq(1)
    end

    it 'counts multiple values' do
      c1 = TContainer.new 'c1@example.com', TValue.new
      c2 = TContainer.new 'c2@example.com', TValue.new
      c1.adopt c2
      expect(c1.count).to eq(2)
    end

    it 'with some empty containers, does not count empties' do
      c1 = TContainer.new 'c1@example.com', TValue.new
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
          c3 = TContainer.new 'c3@example.com', TValue.new
          c2.adopt c3
      expect(c1.count).to eq(2)
    end
  end

  describe "#depth" do
    it "is 0 for the root value" do
      c = TContainer.new 'c1@example.com'
      expect(c.depth).to eq(0)
    end

    it "is 1 for any child" do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
        c3 = TContainer.new 'c3@example.com'
        c1.adopt c3
      expect(c2.depth).to eq(1)
      expect(c3.depth).to eq(1)
    end

    it "is 2 for a grandchild" do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
          c3 = TContainer.new 'c3@example.com'
          c2.adopt c3
      expect(c3.depth).to eq(2)
    end
  end

  describe '#empty?' do
    it 'considers a container without a value empty' do
      c = TContainer.new 'id@example.com'
      expect(c).to be_empty
    end
    it 'considers a container with a value not empty' do
      c = TContainer.new('id@example.com', TValue.new)
      expect(c).to_not be_empty
    end
  end

  describe '#to_s' do
    it 'identifies empty containers' do
      c = TContainer.new('c@example.com')
      expect(c.to_s).to include('empty')
    end
  end

  describe '#child_of?' do
    it 'considers children to be childs of their parents' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
      expect(c2).to be_a_child_of(c1)
    end

    it 'considers grandchildren to be childs of their grandparents' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
          c3 = TContainer.new 'c3@example.com'
          c2.adopt c3
      expect(c3).to be_a_child_of(c1)
    end

    it 'does not consider parents to be childs of their children' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
      expect(c1).to_not be_a_child_of(c2)
    end
    
    it 'does not consider unrelated containers to be children of each other' do
      c1 = TContainer.new 'c1@example.com'
      c2 = TContainer.new 'c2@example.com'
      expect(c1).to_not be_a_child_of(c2)
      expect(c2).to_not be_a_child_of(c1)
    end
  end

  describe '#root?' do
    it 'considers the top container with value to be the root' do
      c1 = TContainer.new '1@example.com', TValue.new
        c2 = TContainer.new '2@example.com', TValue.new
        c1.adopt c2
      expect(c1).to be_root
      expect(c2).to_not be_root
    end

    it 'considers empty containers to be the root' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com', TValue.new
        c1.adopt c2
      expect(c1).to be_root
      expect(c2).to_not be_root
    end

    it 'does not consider a child container to be the root' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
      expect(c2).to_not be_root
    end
  end

  describe '#root' do
    it 'finds the root container from any container' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
          c3 = TContainer.new 'c3@example.com'
          c2.adopt c3
      expect(c1.root).to be(c1)
      expect(c2.root).to be(c1)
      expect(c3.root).to be(c1)
    end
  end

  describe '#each' do
    it 'iterates in reading order, an in-order traversal' do
      c1 = TContainer.new 'c1'
        c2 = TContainer.new 'c2'
        c1.adopt c2
          c3 = TContainer.new 'c3'
          c2.adopt c3
        c4 = TContainer.new 'c4'
        c1.adopt c4

      seen = c1.collect { |c| c.key }
      expect(seen).to eq(%w(c1 c2 c3 c4))
    end
  end

  describe '#effective_root' do
    it 'is a container with a value' do
      c1 = TContainer.new 'c1@example.com', TValue.new
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
      expect(c1.effective_root).to be(c1)
    end

    it 'is an empty container with multiple children' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com', TValue.new
        c1.adopt c2
        c3 = TContainer.new 'c3@example.com', TValue.new
        c1.adopt c3
      expect(c1.effective_root).to be(c1)
    end

    it 'is not an empty container with one child' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com', TValue.new
        c1.adopt c2
      expect(c1.effective_root).not_to be(c1)
    end
  end

  describe '#effective_field' do
    it 'gets fields from the value' do
      c = TContainer.new 'id@example.com', TValue.new('field')
      expect(c.effective_field(:field)).to eq('field')
    end

    it 'gets fields from the first non-empty container (in-order traversal)' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2
          c3 = TContainer.new 'c3@example.com', TValue.new('c3')
          c2.adopt c3
        c4 = TContainer.new 'c4@example.com', TValue.new('c4')
        c1.adopt c4
      expect(c1.effective_field(:field)).to eq('c3')
    end
  end

  describe '#orphan' do
    it 'breaks parent/child relationships' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2

      c2.orphan
      expect(c1.children).to be_empty
      expect(c2).to be_orphan
    end
  end

  describe '#disown' do
    it 'causes a parent to stop considering a conatiner its child' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2

      c1.send(:disown, c2)
      expect(c1.children).to be_empty
      # warning: disown is to be called only by orphan; c2 still thinks c1 is
      # its parent - the world is in an inconsistent state
    end
  end

  describe '#parent=' do
    it 'tells a child what its parent is' do
      c1 = TContainer.new 'c1@example.com'
      c2 = TContainer.new 'c2@example.com'
      c2.send(:parent=, c1)

      expect(c2.parent).to be(c1)
    end
  end

  describe '#value=' do
    it 'accepts messages to empty containers' do
      c = TContainer.new 'c@example.com'
      v = TValue.new
      c.value = v
      expect(c.value).to be(v)
    end

    it 'rejects messages if not empty' do
      c = TContainer.new 'id@example.com', TValue.new
      v = TValue.new
      expect {
        c.value = v
      }.to raise_error(/non-empty/)
    end
  end

  describe '#adopt' do
    # Calls to adopt that would set up a cyclical graph should just be quietly
    # ignored. Because we're parenting based on references that are often
    # genereated incopetently, and can be generated maliciously, it's not an
    # exceptional circumstance the threader really cares to know about.
    it 'adopts containers' do
      c1 = TContainer.new 'c1@example.com'
      c2 = TContainer.new 'c2@example.com'
      expect(c1.children).to be_empty
      expect(c2).to be_orphan
      c1.adopt(c2)
      expect(c2.parent).to be(c1)
      expect(c2.root).to be(c1)
      expect(c1.children).to eq([c2])
      expect(c2).to_not be_orphan
    end

    it 'does not adopt itself' do
      c1 = TContainer.new 'c@example.com'
      c1.adopt c1
      expect(c1).to be_orphan
      expect(c1.children).to be_empty
    end

    it 'does not adopt its parent' do
      c1 = TContainer.new 'c1@example.com'
      c2 = TContainer.new 'c2@example.com'
      c1.adopt(c2)
      c2.adopt(c1)
      expect(c1).to be_root
      expect(c2.parent).to be(c1)
    end

    it 'allows adopting an already-parented container' do
      c1 = TContainer.new 'c1@example.com'
        c2 = TContainer.new 'c2@example.com'
        c1.adopt c2

      other = TContainer.new 'other@example.com'
      other.adopt(c2)
      expect(c2.parent).to be(other)
      expect(c1.children).to be_empty
    end
  end

end
