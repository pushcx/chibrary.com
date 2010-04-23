require File.dirname(__FILE__) + '/../test_helper'
require 'permutation'

class ContainerTest < ThreadingTest
  context 'a cachedhash' do
    setup do
      addresses = mock('addresses')
      addresses.expects(:[]).at_least(0).returns('example')
      CachedHash.expects(:new).with('list_address').at_least(0).returns(addresses)
    end

    should 'initialize empty' do
      c = Container.new 'id@example.com'
      assert c.empty?
      assert c.orphan?
      assert c.children.empty?

      c = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      assert !c.empty?
    end

    should 'export to yaml' do
      c = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      assert !c.to_yaml.include?('Message body')
    end

    should 'consider containers with equal contents equal' do
      c1  = Container.new '1@example.com'
      c1_ = Container.new '1@example.com'
      c2  = Container.new '2@example.com'
      assert c1 == c1_
      assert c1 != c2

      c1  = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c1_ = Container.new Message.new(threaded_message(:root), 'test', 'rootprim')
      c2  = Container.new Message.new(threaded_message(:child), 'test', '000child')
      assert c1 == c1_
      assert c1 != c2
    end

    should 'count the number of a containers in the tree' do
      assert_equal 0, Container.new('1@example.com').count
      assert_equal 1, Container.new(Message.new(threaded_message(:root), 'test', '0000root')).count
      assert_equal 4, container_tree.count
    end

    should 'track tree depth' do
      c = container_tree
      assert_equal 0, c.depth
      assert_equal 1, c.children.first.depth
      assert_equal 2, c.children.first.children.first.depth
    end

    should 'register as empty' do
      c = Container.new('root@example.com')
      assert c.empty?
      assert_nil c.message
      assert !Container.new(Message.new(threaded_message(:root), 'test', '0000root')).empty?
    end

    should 'consider empty containers as likely split' do
      c = Container.new('root@example.com')
      assert c.likely_split_thread?
    end

    should 'consider a message without a parent as likely split' do
      c = Container.new Message.new(threaded_message(:child), 'test', '000child')
      assert c.likely_split_thread?
    end

    should 'print debugging' do
      str = Container.new('root@example.com').to_s
      assert_match /root@example.com/, str
      assert_match /empty/, str

      str = Container.new(Message.new(threaded_message(:root), 'test', '0000root')).to_s
      assert_match /root@example.com/, str
      assert_no_match /empty/, str
    end

    should 'track children and parents' do
      c1 = container_tree
      assert !c1.child_of?(c1.children.first)
      assert c1.children.first.child_of?(c1)
      assert c1.children.first.child_of?(c1.children.first)
      assert c1.children.first.children.first.child_of?(c1)
      assert !c1.child_of?(c1.children.first.children.first)
    end

    should 'consider only the first message the root' do
      container_tree.each do |container|
        if container.message_id == 'root@example.com'
          assert container.root?
        else
          assert !container.root?
        end
      end
    end

    should 'access the root' do
      c = container_tree
      c.each do |container|
        assert_equal c, container.root
      end
    end

    should 'iterate over containers' do
      seen = container_tree.collect { |container|
        assert container.is_a?(Container)
        container.message_id
      }
      assert_equal %w{root child grandchild missing orphan}.collect { |i| "#{i}@example.com" }, seen
    end

    should 'track effective roots' do 
      # The effective root for the each container is itself, except c4's is c5.
      c1 = container_tree
      c1.each do |container|
        if container.message_id == 'missing@example.com'
          # ew here... maybe I should write a find_child?
          assert_equal c1.children.last.children.last.children.last, container.effective_root
        else
          assert_equal container, container.effective_root
        end
      end
    end

    should 'get fields from first non-blank message' do
      c1 = container_tree
      assert_equal 'Threaded Message Fixtures', c1.effective_field(:subject)
      # :missing should delegate cleanly to :orphan
      assert_equal 'Re: Re: Threaded Message Fixtures', c1.children.first.children.last.effective_field(:subject)
    end

    should 'cache an uncached container' do
      c = container_tree
      $archive.expects(:[]).raises(NotFound)
      $archive.expects(:[]=)
      c.expects(:cache_snippet)
      c.cache
    end

    should 'not re-cache cached containers' do
      c = container_tree
      c.expects(:to_yaml).returns("yaml".to_yaml)
      $archive.expects(:[]).returns("yaml")
      c.cache
    end

    should 're-cache a different cached container' do
      c = container_tree
      c.expects(:to_yaml).returns("yaml")
      $archive.expects(:[]).returns("old yaml")
      $archive.expects(:[]=)
      c.expects(:cache_snippet)
      c.cache
    end

    should 'cache a snippet' do
      c = Container.new ''
      body = ">The\nfirst\nfive\n\nunquoted\nnonblank\nlines"
      snippet = {
        :excerpt => "first five unquoted nonblank lines",
        :subject => 'subject',
        :url => '/slug/2009/02/00000000',
      }
      c.expects(:n_subject).returns(snippet[:subject])
      c.expects(:date).times(4).returns(Time.at(1234232107))
      c.expects(:call_number).returns('00000000')
      c.expects(:n_subject).returns('subject')
      c.expects(:effective_field).with(:slug).returns('slug')
      c.expects(:effective_field).with(:body).returns(body)
      c.expects(:last_snippet_key).with('snippet/list/slug').returns(0)
      $archive.expects(:[]=).with('snippet/list/slug/8765767892', snippet)
      c.expects(:last_snippet_key).with('snippet/homepage').returns(0)
      $archive.expects(:[]=).with('snippet/homepage/8765767892', snippet)
      c.cache_snippet
    end

    should_eventually 'ensure snippet times are reasonable'
    # cache_snippet should test to see that timestamps are within the last day
    # and not in the future

    should_eventually 'test last_snippet_key'

    should 'orphan containers to break parent/child relationships' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c1.adopt c2
      
      c1.expects(:disown).with(c2)
      c2.orphan
      assert c2.orphan?
    end

    should 'disown cleanly' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c1.adopt c2

      c1.send(:disown, c2) # protected method, using .send to test
      assert c1.children.empty?
    end

    should 'accept parents' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c2.send(:parent=, c1) # protected method, using .send to test
      assert !c2.orphan?
      assert_equal c1, c2.parent
    end

    should 'accept a message' do
      c = Container.new "root@example.com"
      m = Message.new(threaded_message(:root), 'test', '0000root')
      c.message = m
      assert_equal m, c.message

      assert_raises(RuntimeError, /message id/i) do
        c = Container.new "wrong@example.com"
        m = Message.new(threaded_message(:root), 'test', '0000root')
        c.message = m
      end
    end

    # Calls to adopt that would set up a cyclical graph should just be quietly
    # ignored. Because we're parenting based on possibly-malicious and often
    # incompetently-generated references, it's not an exceptional circumstance
    # the threader really cares to know about.

    should 'not adopt itself' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c1.adopt c1
      assert c1.orphan?
      assert c1.children.empty?
    end

    should 'not adopt its parent' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c1.adopt c2
      c1.adopt c2
      assert_equal c1, c2.parent
      assert c1.children.include?(c2)
      assert c1.root?
      assert c2.children.empty?
    end

    should 'adopt containers' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')

      assert c1.children.empty?
      assert c2.orphan?
      c1.adopt c2
      assert_equal c1, c2.root
      assert_equal [c2], c1.children
      assert !c2.orphan?
    end

    should 'not adopt an already-parented container' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c3 = Container.new Message.new(threaded_message(:grandchild), 'test', 'grndchld')
      c1.adopt c2
      c3.adopt c2
      assert_equal c1, c2.parent
      assert c1.children.include?(c2)
      assert !c1.children.include?(c3)
      assert c3.children.empty?
    end

    should 'trust parenting when adopting' do
      c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c3 = Container.new Message.new(threaded_message(:grandchild), 'test', 'grndchld')
      c1.adopt c3
      c2.adopt c3
      assert_equal c2, c3.parent
      assert c1.children.empty?
      assert c2.children.include?(c3)
    end

  end
end
