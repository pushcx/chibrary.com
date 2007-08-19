require File.dirname(__FILE__) + '/../test_helper'
require 'threading'
require 'message'

class ThreadingTest < Test::Unit::TestCase
  fixtures :message

  def test_dummy ; end

  private
  def container_tree prefix=''
    c1 = Container.new "#{prefix}1"
    c1.message = Message.new message(:good), 'test', '00000000'

      c2 = Container.new "#{prefix}2"
      c2.message = Message.new message(:good), 'test', '00000000'
      c2.parent = c1
      c1.children << c2

        c3 = Container.new "#{prefix}3"
        c3.message = Message.new message(:good), 'test', '00000000'
        c3.parent = c2
        c2.children << c3

        c4 = Container.new "#{prefix}4"
        c4.parent = c2
        c2.children << c4

          c5 = Container.new "#{prefix}5"
          c5.message = Message.new message(:good), 'test', '00000000'
          c5.parent = c4
          c4.children << c5

    c1
  end
end

class ContainerTest < ThreadingTest
  def test_initialize
    Container.new '0'
    assert_raises(RuntimeError, "non-String 0") do
      Container.new 0
    end
  end

  def test_each_with_stuff
    c1, c2, c4 = nil
    seen = []
    container_tree.each_with_stuff do |container, depth, parent|
      assert_equal Container, container.class
      seen << container.id
      case container.id
      when '1'
        assert_equal 0, depth
        assert_equal nil, parent
        c1 = container
      when '2'
        assert_equal 1, depth
        assert_equal c1, parent
        c2 = container
      when '3'
        assert_equal 2, depth
        assert_equal c2, parent
      when '4'
        assert_equal 2, depth
        assert_equal c2, parent
        c4 = container
      when '5'
        assert_equal 3, depth
        assert_equal c4, parent
      else
        fail "unknown container yielded"
      end
    end
    assert_equal %w{1 2 3 4 5}, seen
  end

  def test_descendant_of?
    c1 = container_tree
    assert !c1.descendant_of?(c1.children.first)
    assert c1.children.first.descendant_of?(c1)
    assert c1.children.first.descendant_of?(c1.children.first)
    assert c1.children.first.children.first.descendant_of?(c1)
    assert !c1.descendant_of?(c1.children.first.children.first)
  end

  def test_equality
    c1 = Container.new '1'
    c1_ = Container.new '1'
    c2 = Container.new '2'
    assert c1 == c1_
    assert !(c1 == c2)
  end

  def test_empty?
    c = Container.new '1'
    assert c.empty?
    c.message = Message.new message(:good), 'test', '00000000'
    assert !c.empty?
  end

  def test_root?
    container_tree.each_with_stuff do |container, d, p|
      case container.id
      when '1': assert container.root?
      else      assert !container.root?
      end
    end
  end

  def test_root
    c1 = container_tree
    c1.each_with_stuff do |container, d, p|
      assert_equal c1, container.root
    end
  end

  def test_first_useful_descendant
    c1 = container_tree
    assert_equal c1, c1.first_useful_descendant # c1's is c1
    assert_equal c1.children.first, c1.children.first.first_useful_descendant # c2's is c2
    assert_equal c1.children.first.children.last.children.first, c1.children.first.children.last.first_useful_descendant # c4's is c5
  end

  def test_find_attr
    c1 = container_tree
    assert_equal 'Good message', c1.find_attr(:subject)
    assert_equal 'Good message', c1.children.first.children.last.find_attr(:subject)
  end

  def test_is_reply?
    c = Container.new '1'
    assert_equal nil, c.is_reply?

    message = mock()
    message.expects(:subject).returns('foo').at_least_once
    c.message = message
    assert_equal false, c.is_reply?

    message = mock()
    message.expects(:subject).returns('re: foo').at_least_once
    c.message = message
    assert_equal true, c.is_reply?
  end

  def test_to_s
    c1 = container_tree
    assert_match /1/, c1.to_s # must give id
    assert_match /2/, c1.to_s # must give child id
    assert_match /2/, c1.children.first.to_s # c2
    assert_match /3/, c1.children.first.children.first.to_s # c3
    assert_match /4/, c1.children.first.children.last.to_s  # c4
  end
end

class LLThreadTest < ThreadingTest
  def test_drop
    t = LLThread.new
    t << c = Container.new('1')
    t.drop c
    assert_equal [], t.containers
    # removed the raise; malicious input can raise things
    #assert_raises(RuntimeError) do
    #  t.drop c
    #end
  end

  def test_each
    t = LLThread.new
    t << container_tree('a')
    t << container_tree('b')
    seen = []
    t.each do |message, depth, parent|
      seen << message.message_id if message.instance_of? Message
    end
    assert_equal ['goodid@example.com'] * 8, seen
  end

  private
  def test_to_base_64
    
  end
end

class ThreadSetTest < ThreadingTest
  class FakeMessage
    attr_accessor :message_id, :subject, :references
    def initialize message_id, subject, references ; @message_id = message_id ; @subject = subject ; @references = references ; end
    def date ; Time.now ; end
  end

  def test_caching
    # create a vaguely real-shaped message tree
    ts = ThreadSet.new
    subjects = %w{foo bar baz quux lamb all makes human continued world}
    100.downto(0) do |i|
      ts.add_message FakeMessage.new(i.to_s, subjects[rand(subjects.size)], [(rand(400) / 4).to_s])
    end
    # dump it to YAML and reload it
    ts = YAML::load(ts.to_yaml)
    # add a few more messages for luck
    120.downto(101) do |i|
      ts.add_message FakeMessage.new(i.to_s, subjects[rand(subjects.size)], [(rand(100) / 4).to_s])
    end
    #ts.dump $stdout
  end
end
