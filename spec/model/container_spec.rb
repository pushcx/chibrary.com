require_relative '../rspec'
require_relative '../../value/summary'
require_relative '../../model/container'
require_relative '../../model/message'

module Chibrary

TValue = Struct.new(:field)

describe Container do

  # Generic container key/value/tree code ----------------------------

  describe '#initialize' do
    it 'is empty with just a key' do
      c = Container.new 'id@example.com'
      expect(c).to be_empty
      expect(c).to be_orphan
      expect(c.children).to be_empty
    end

    it 'is not empty with a value' do
      c = Container.new('id@example.com', TValue.new)
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

    it 'considers containers with the same key equal, ignoring value diffs' do
      c1  = Container.new 'c1@example.com', TValue.new
      c1_ = Container.new 'c1@example.com', nil
      c2  = Container.new 'c2@example.com', TValue.new
      expect(c1).to eq(c1_)
      expect(c1).to_not eq(c2)
    end
  end

  describe '#count' do
    it 'does not count empty containers' do
      c = Container.new '1@example.com'
      expect(c.count).to eq(0)
    end

    it 'does count values' do
      c = Container.new '1@example.com', TValue.new
      expect(c.count).to eq(1)
    end

    it 'counts multiple values' do
      c1 = Container.new 'c1@example.com', TValue.new
      c2 = Container.new 'c2@example.com', TValue.new
      c1.adopt c2
      expect(c1.count).to eq(2)
    end

    it 'with some empty containers, does not count empties' do
      c1 = Container.new 'c1@example.com', TValue.new
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com', TValue.new
          c2.adopt c3
      expect(c1.count).to eq(2)
    end
  end

  describe "#depth" do
    it "is 0 for the root value" do
      c = Container.new 'c1@example.com'
      expect(c.depth).to eq(0)
    end

    it "is 1 for a direct child" do
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
    it 'considers a container without a value empty' do
      c = Container.new 'id@example.com'
      expect(c).to be_empty
    end

    it 'considers a container with a value not empty' do
      c = Container.new('id@example.com', TValue.new)
      expect(c).to_not be_empty
    end
  end

  describe '#to_s' do
    it 'identifies empty containers' do
      c = Container.new('c@example.com')
      expect(c.to_s).to include('empty')
    end

    it 'includes message id with a Message' do
      c = Container.new('c@example.com', FakeMessage.new('c@example.com'))
      expect(c.to_s).to include('c@example.com')
    end

    it 'includes message id with a Summary' do
      s = Summary.new 'callnumb', 'c@example.com', 'from@example.com', 'subject', Time.now, 'blurb'
      c = Container.new('c@example.com', s)
      expect(c.to_s).to include('c@example.com')
    end
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

    it 'does not consider unrelated containers to be children of each other' do
      c1 = Container.new 'c1@example.com'
      c2 = Container.new 'c2@example.com'
      expect(c1).to_not be_a_child_of(c2)
      expect(c2).to_not be_a_child_of(c1)
    end
  end

  describe '#root?' do
    it 'considers the top container with value to be the root' do
      c1 = Container.new '1@example.com', TValue.new
        c2 = Container.new '2@example.com', TValue.new
        c1.adopt c2
      expect(c1).to be_root
      expect(c2).to_not be_root
    end

    it 'considers empty containers to be the root' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com', TValue.new
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
    it 'finds the root container from any container' do
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
      c1 = Container.new 'c1'
        c2 = Container.new 'c2'
        c1.adopt c2
          c3 = Container.new 'c3'
          c2.adopt c3
        c4 = Container.new 'c4'
        c1.adopt c4

      seen = c1.collect { |c| c.key }
      expect(seen).to eq(%w(c1 c2 c3 c4))
    end
  end

  describe '#effective_root' do
    it 'is a container with a value' do
      c1 = Container.new 'c1@example.com', TValue.new
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
      expect(c1.effective_root).to be(c1)
    end

    it 'is an empty container with multiple children' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com', TValue.new
        c1.adopt c2
        c3 = Container.new 'c3@example.com', TValue.new
        c1.adopt c3
      expect(c1.effective_root).to be(c1)
    end

    it 'is a lone child of an empty container' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com', TValue.new
        c1.adopt c2
      expect(c1.effective_root).to be(c2)
    end
  end

  describe '#effective_field' do
    it 'gets fields from the value' do
      c = Container.new 'id@example.com', TValue.new('field')
      expect(c.effective_field(:field)).to eq('field')
    end

    it 'gets fields from the first non-empty container (in-order traversal)' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2
          c3 = Container.new 'c3@example.com', TValue.new('c3')
          c2.adopt c3
        c4 = Container.new 'c4@example.com', TValue.new('c4')
        c1.adopt c4
      expect(c1.effective_field(:field)).to eq('c3')
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

    it 'allows adopting an already-parented container' do
      c1 = Container.new 'c1@example.com'
        c2 = Container.new 'c2@example.com'
        c1.adopt c2

      other = Container.new 'other@example.com'
      other.adopt(c2)
      expect(c2.parent).to be(other)
      expect(c1.children).to be_empty
    end
  end

  describe '::unwrap' do
    it 'given a Container, returns its value' do
      c = Container.new 'key', 3
      expect(Container.unwrap c).to eq(3)
    end

    it 'given a value, returns it' do
      expect(Container.unwrap 3).to eq(3)
    end
  end

  # Message/Summary-specific code below this line --------------------

  describe 'aliasing' do
    it 'aliases #message_id to #key' do
      mc = Container.new 'foo@example.com'
      expect(mc.message_id).to eq('foo@example.com')
    end

    it 'aliases #message to #value' do
      message = FakeMessage.new('fake@example.com')
      mc = Container.new 'fake@example.com', message
      expect(mc.message).to eq(message)
    end

    it 'aliases #message= to #value=' do
      message = FakeMessage.new('fake@example.com')
      mc = Container.new 'fake@example.com'
      mc.message = message
      expect(mc.value).to eq(message)
    end
  end

  describe '#value=' do
    it 'accepts messages to empty containers' do
      c = Container.new 'c@example.com'
      v = TValue.new
      c.value = v
      expect(c.value).to be(v)
    end

    it 'rejects values if not empty' do
      c = Container.new 'id@example.com', TValue.new
      v = TValue.new
      expect {
        c.value = v
      }.to raise_error(ContainerNotEmpty)
    end

    it 'rejects Messages with different ids' do
      c = Container.new 'container@example.com'
      m = FakeMessage.new('fake@example.com')
      expect {
        c.message = m
      }.to raise_error(/doesn't match/)
    end

    it 'rejects Summaries with different ids' do
      c = Container.new 'container@example.com'
      s = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'subject', Time.now, 'blurb'
      expect {
        c.message = s
      }.to raise_error(/doesn't match/)
    end
  end

  describe 'effective fields with value' do
    class FieldsValue
      def slug ; 'slug' ; end
      def call_number ; 'callnumb' ; end
      def date ; Time.new(2013, 11, 21) ; end
      def subject ; 'Re: cats' ; end
      def n_subject ; 'cats' ; end
      def blurb ; 'blurb' ; end
      def references ; ['thirty-five ham and cheese sandwiches'] ; end
    end
    let(:c) { Container.new 'c@example.com', FieldsValue.new }

    it('#slug'){ expect(c.slug).to eq('slug') }
    it('#call_number'){ expect(c.call_number).to eq('callnumb') }
    it('#date'){ expect(c.date).to eq(Time.new(2013, 11, 21)) }
    it('#subject'){ expect(c.subject).to eq('Re: cats') }
    it('#n_subject'){ expect(c.n_subject).to eq('cats') }
    it('#blurb'){ expect(c.blurb).to eq('blurb') }
    it('#references'){ expect(c.references).to eq(['thirty-five ham and cheese sandwiches']) }
  end

  describe 'effective fields without value' do
    let(:c) { Container.new 'c@example.com' }
    let(:now) { Time.now }
    before { Time.stub(:now).and_return(now) }

    it('#slug'){ expect(c.slug).to eq(nil) }
    it('#call_number'){ expect(c.call_number).to eq('') }
    it('#date'){ expect(c.date).to eq(now) }
    it('#subject'){ expect(c.subject).to eq('') }
    it('#n_subject'){ expect(c.n_subject).to eq('') }
    it('#blurb'){ expect(c.blurb).to eq('') }
    it('#references'){ expect(c.references).to eq([]) }
  end

  describe '#<=>' do
    class DateValue
      attr_reader :date
      def initialize date
        @date = date
      end
    end

    it "sorts by date if values have dates" do
      c1 = Container.new 'id', DateValue.new(Time.now - 1)
      c2 = Container.new 'id', DateValue.new(Time.now)
      expect([c2, c1].sort).to eq([c1, c2])
    end

    it "sorts by key otherwise" do
      c1 = Container.new 'a'
      c2 = Container.new 'b'
      expect([c2, c1].sort).to eq([c1, c2])
    end
  end

  describe '#likely_split_thread?' do
    # delegates to message and does not need testing
  end

  describe "#subject_shorter_than?" do
    # this is too stupidly simple to test
  end

  # Summaryaize/Messagize return new Containers... unless they already have a
  # Summary/Message as requested, then return themselves. This is a
  # performance hack, but since Containers aren't immutable, could get you
  # into trouble when you surprisingly share an objref...
  describe "#summarize" do
    context "with a Summary" do
      it 'returns itself' do
        s = Summary.new 'callnumb', '1@example.com', 'from@example.com', 'subject', Time.now, 'blurb'
        c = Container.new 'c@example.com', s
        expect(c.summarize).to be(c)
      end
    end

    context "with a Message it returns equivalent Container with Summary" do
      let(:m1) { Message.from_string "Subject: m1\n\nm1", 'callnum1', 'slug' }
      let(:m2) { Message.from_string "Subject: m2\n\nm2", 'callnum2', 'slug' }
      let(:c1) { Container.new 'c1@example.com', m1 }
      let(:c2) { Container.new 'c2@example.com', m2 }
      before   { c1.adopt c2 }
      subject  { c1.summarize }

      expect_it { to be_a Container }
      it { expect(subject.value).to be_a(Summary) }
      it { expect(subject.call_number).to eq('callnum1') }
      it { expect(subject.n_subject).to eq('m1') }

      it { expect(subject.children.first.value).to be_a(Summary) }
      it { expect(subject.children.first.call_number).to eq('callnum2') }
      it { expect(subject.children.first.n_subject).to eq('m2') }

    end
  end

  describe "#messagize" do
    context "with a Message" do
      it 'returns itself' do
        m = Message.from_string "Subject: m1\n\nm1", 'callnum1', 'slug'
        c = Container.new 'c@example.com', m
        expect(c.messagize []).to be(c)
      end
    end

    context "with a Summary it returns equivalent Container with Message" do
      let(:m1) { Message.from_string "Subject: m1\n\nm1", 'callnum1', 'slug' }
      let(:m2) { Message.from_string "Subject: m2\n\nm2", 'callnum2', 'slug' }
      let(:messages) { { 'callnum1' => m1, 'callnum2' => m2 } }

      let(:s1) { Summary.new 'callnum1', 'c1@example.com', '1@example.com', 'm1', Time.now, 'blurb' }
      let(:s2) { Summary.new 'callnum2', 'c2@example.com', '2@example.com', 'm2', Time.now, 'blurb' }
      let(:c1) { Container.new 'c1@example.com', s1 }
      let(:c2) { Container.new 'c2@example.com', s2 }
      before   { c1.adopt c2 }
      subject  { c1.messagize messages }

      expect_it { to be_a Container }
      it { expect(subject.value).to be_a(Message) }
      it { expect(subject.call_number).to eq('callnum1') }
      it { expect(subject.message_id).to eq('c1@example.com') }
      it { expect(subject.subject).to eq('m1') }

      it { expect(subject.children.first.value).to be_a(Message) }
      it { expect(subject.children.first.call_number).to eq('callnum2') }
      it { expect(subject.children.first.subject).to eq('m2') }
    end
  end
end

end # Chibrary
