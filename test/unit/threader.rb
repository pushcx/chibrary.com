require File.dirname(__FILE__) + '/../test_helper'
require 'threader'
require 'message'

class ThreaderTest < Test::Unit::TestCase
  fixtures :message

  def setup
    $stdout.expects(:puts).at_least(0)
    @queue = mock("queue")
    Queue.expects(:new).returns(@queue)
  end

  def test_get_job
    t = Threader.new

    job = mock("job")
    @queue.expects(:next).returns(job)
    assert_equal job, t.get_job

    @queue.expects(:next).returns(nil)
    assert_equal nil, t.get_job
  end

  def test_run_empty
    t = new_threader

    # no messages in cache or bucket
    AWS::S3::S3Object.expects(:load_yaml).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])

    # threader should exit cleanly
    t.run
  end

  def test_run_removed
    t = new_threader

    # one message in cache, none in list
    AWS::S3::S3Object.expects(:load_yaml).returns(["goodid@example.com"], mock)
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])
    ts = mock
    ThreadSet.expects(:new).returns(ts)

    t.expects(:cache_work).with('example', '2008', '08', [], ts)
    t.expects(:queue_renderer).with('example', '2008', '08', ts)
    t.run
  end

  def test_run_add_message
    t = new_threader
    AWS::S3::S3Object.expects(:load_yaml).returns(["1@example.com"])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns(["1@example.com", "2@example.com"])
    message = mock
    Message.expects(:new).with("2@example.com").returns(message)
    ts = mock
    ts.expects(:<<).with(message)
    ThreadSet.expects(:month).returns(ts)

    t.expects(:cache_work)
    t.expects(:queue_renderer)
    t.run
  end

  def test_run_multiple_jobs
    t = Threader.new

    # two empty jobs
    job1 = Job.new :thread, :slug => 'example', :year => '2008', :month => '07'
    AWS::S3::S3Object.expects(:load_yaml).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/07/').returns([])

    job2 = Job.new :thread, :slug => 'example', :year => '2008', :month => '08'
    AWS::S3::S3Object.expects(:load_yaml).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])

    t.expects(:get_job).times(3).returns(job1, job2, nil)
    t.run
  end

  def test_cache_work_empty
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    threadset = mock
    threadset.expects(:collect).returns([])
    AWS::S3::S3Object.expects(:store).with("list/example/message_list/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })
    CachedHash.expects(:new).with('render/month/example').returns(stub_everything('render_month'))

    t.cache_work slug, year, month, message_list, threadset
  end

  def test_cache_work_cached
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    AWS::S3::S3Object.expects(:store).with("list/example/message_list/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })

    thread = mock("thread")
    thread.expects(:to_yaml).returns("yaml")
    thread.expects(:call_number).at_least_once.returns('00000000')
    threadset = mock("threadset")
    threadset.expects(:collect).yields(thread)

    o = mock("object")
    o.expects(:about).returns({ 'content-length' => "yaml".length })
    AWS::S3::S3Object.expects(:find).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(o)
    CachedHash.expects(:new).with('render/month/example').returns(stub_everything('render_month'))

    t.cache_work slug, year, month, message_list, threadset
  end

  def test_cache_work_uncached
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    AWS::S3::S3Object.expects(:store).with("list/example/message_list/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })

    thread = mock
    thread.expects(:count).returns(1)
    thread.expects(:to_yaml).returns("yaml")
    thread.expects(:call_number).at_least_once.returns('00000000')
    thread.expects(:subject).returns('subject')
    threadset = mock
    threadset.expects(:collect).yields(thread)
    AWS::S3::S3Object.expects(:find).with("list/example/thread/2007/08/00000000", "listlibrary_archive").raises(RuntimeError)
    CachedHash.expects(:new).with('render/month/example').returns(stub_everything('render_month'))
    AWS::S3::S3Object.expects(:store).with('list/example/thread/2007/08/00000000', 'yaml', 'listlibrary_archive', {:content_type => 'text/plain'})

    t.cache_work slug, year, month, message_list, threadset
  end

  def test_queue_renderer
    threadset = mock("threadset")
    threadset.expects(:each).yields(mock(:call_number => '00000001'))
    Queue.expects(:new).with(:render_thread).returns(mock("thread_q", :add => nil))
    Queue.expects(:new).with(:render_month).returns(mock("month_q", :add => nil))
    Queue.expects(:new).with(:render_list).returns(mock("list_q", :add => nil))

    Threader.new.queue_renderer "example", "2008", "08", threadset
  end

  private
  def new_threader
    t = Threader.new
    job = Job.new :thread, :slug => 'example', :year => '2008', :month => '08'
    t.expects(:get_job).returns(job, nil).at_least_once
    t
  end
end
