require 'test_helper'

class JobTest < ActiveSupport::TestCase
  should 'raise errors for new, unknown job types' do
    assert_raises(RuntimeError, /unknown job type/) do
      Job.new :foo, []
    end
  end

  should 'report its attributes' do
    job = Job.new :import_mailman, { :slug => 'example' }
    assert_equal :import_mailman, job.type
    assert_equal 'example', job.attributes[:slug]
  end

  should 'have a slug' do
    job = Job.new :import_mailman, { :slug => 'example' }
    assert_equal 'example', job[:slug]
  end

  should 'store to a named key' do
    job = Job.new :thread, { :slug => 'example', :year => '2008', :month => '01' }
    assert_equal 'example/2008/01', job.key
  end
end

class QueueTest < ActiveSupport::TestCase
  should 'raise errors for new, unknown job types' do
    assert_raises(RuntimeError, /unknown job type/) do
      Queue.new :foo
    end
  end

  should 'report its attributes' do
    CachedHash.expects(:new)
    queue = Queue.new :import_mailman
    assert_equal :import_mailman, queue.type
  end

  should 'add to the queue' do
    CachedHash.expects(:new).returns(mock("queue", :[]= => nil))
    queue = Queue.new :import_mailman
    queue.add :slug => 'example'
  end

  should 'run through queue jobs' do
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

  should 'do nothing when the queue is empty' do
    CachedHash.expects(:new).returns(mock("queue"))
    queue = Queue.new :import_mailman
    c = mock
    c.expects(:first).returns(nil)
    $cachedhash.expects(:[]).times(2).returns(c, nil)
    assert_equal nil, queue.work { |job| raise "Should not have had a job yielded" }
  end

  should 'handle jobs that disappear' do
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
