require File.dirname(__FILE__) + '/../test_helper'
require 'queue'

class JobTest < Test::Unit::TestCase
  def test_new_bad_type
    assert_raises(RuntimeError, /unknown job type/) do
      Job.new :foo, []
    end
  end

  def test_new
    job = Job.new :render_list, { :slug => 'example' }
    assert_equal :render_list, job.type
    assert_equal 'example', job.attributes[:slug]
  end

  def test_hash
    job = Job.new :render_list, { :slug => 'example' }
    assert_equal 'example', job[:slug]
  end

  def test_key
    job = Job.new :render_month, { :slug => 'example', :year => '2008', :month => '01' }
    assert_equal 'render_month/example/2008/01', job.key
  end
end

class QueueTest < Test::Unit::TestCase
  def test_new_bad_type
    assert_raises(RuntimeError, /unknown job type/) do
      Queue.new :foo
    end
  end

  def test_new
    CachedHash.expects(:new)
    queue = Queue.new :render_list
    assert_equal :render_list, queue.type
  end

  def test_add
    CachedHash.expects(:new).returns(mock("queue", :[]= => nil))
    queue = Queue.new :render_list
    queue.add :slug => 'example'
  end

  def test_next
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :render_list
    c = mock
    c.expects(:first_key).returns("key")
    c.expects(:[]).returns("job")
    c.expects(:delete)
    $cachedhash.expects(:[]).returns(c)
    assert_equal "job", queue.next
  end

  def test_next_none
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :render_list
    c = mock
    c.expects(:first_key).returns(nil)
    $cachedhash.expects(:[]).returns(c)
    assert_equal nil, queue.next
  end

  def test_next_gone
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :render_list
    object1 = mock("object1")
    c = mock
    c.expects(:first_key).times(2).returns("taken key", "good key")
    c.expects(:[]).times(2).raises(RuntimeError, "key deleted").then.returns("job")
    c.expects(:delete)
    $cachedhash.expects(:[]).returns(c)
    assert_equal "job", queue.next
  end
end
