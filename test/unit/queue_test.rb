require 'test_helper'
require 'queue'

class JobTest < ActiveSupport::TestCase
  def test_new_bad_type
    assert_raises(RuntimeError, /unknown job type/) do
      Job.new :foo, []
    end
  end

  def test_new
    job = Job.new :import_mailman, { :slug => 'example' }
    assert_equal :import_mailman, job.type
    assert_equal 'example', job.attributes[:slug]
  end

  def test_hash
    job = Job.new :import_mailman, { :slug => 'example' }
    assert_equal 'example', job[:slug]
  end

  def test_key
    job = Job.new :thread, { :slug => 'example', :year => '2008', :month => '01' }
    assert_equal 'example/2008/01', job.key
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
    queue = Queue.new :import_mailman
    assert_equal :import_mailman, queue.type
  end

  def test_add
    CachedHash.expects(:new).returns(mock("queue", :[]= => nil))
    queue = Queue.new :import_mailman
    queue.add :slug => 'example'
  end

  def test_work
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :import_mailman
    c_q = mock("queue cachedhash")
    c_q.expects(:first).times(2).returns("key", nil)
    c_q.expects(:[]).with("key").returns("job")
    c_q.expects(:delete)
    inp_q = mock("in_progress cachedhash")
    inp_q.expects(:[]=)
    inp_q.expects(:delete)
    $cachedhash.expects(:[]).times(2).returns(c_q, inp_q)
    queue.work { |j| assert_equal 'job', j }
  end

  def test_work_none
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :import_mailman
    c = mock
    c.expects(:first).returns(nil)
    $cachedhash.expects(:[]).times(2).returns(c, nil)
    assert_equal nil, queue.work { |job| raise "Should not have had a job yielded" }
  end

  def test_work_gone
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :import_mailman
    c_q = mock("queue cachedhash")
    c_q.expects(:first).times(3).returns("taken key", "good key", nil)
    c_q.expects(:[]).times(2).returns(nil).then.returns("job")
    c_q.expects(:delete)
    inp_q = mock("in_progress cachedhash")
    inp_q.expects(:[]=)
    inp_q.expects(:delete)
    $cachedhash.expects(:[]).times(2).returns(c_q, inp_q)
    queue.work { |j| assert_equal 'job', j }
  end
end
