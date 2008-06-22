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
    list = mock("list")
    list.expects(:cached_message_list).returns([])
    list.expects(:fresh_message_list).returns([])
    List.expects(:new).returns(list)

    # threader should exit cleanly
    t.run
  end

  def test_run_removed
    t = new_threader

    # one message in cache, none in list
    list = mock("list")
    list.expects(:cached_message_list).returns(["1@example.com"])
    list.expects(:fresh_message_list).returns([])
    List.expects(:new).returns(list)
    ts = mock
    ThreadSet.expects(:new).returns(ts)

    t.expects(:cache_work).with('example', '2008', '08', [], ts)
    t.run
  end

  def test_run_add_message
    t = new_threader
    list = mock("list")
    list.expects(:cached_message_list).returns(["1@example.com"])
    list.expects(:fresh_message_list).returns(["1@example.com", "2@example.com"])
    List.expects(:new).returns(list)

    message = mock("message")
    $archive.expects(:[]).with('2@example.com').returns(message)
    ts = mock("threadset")
    ts.expects(:<<).with(message)
    ThreadSet.expects(:month).returns(ts)

    t.expects(:cache_work)
    t.run
  end

  def test_run_multiple_jobs
    t = Threader.new

    # two empty jobs
    job1 = Job.new :thread, :slug => 'example', :year => '2008', :month => '07'
    list = mock("list")
    list.expects(:cached_message_list).returns([])
    list.expects(:fresh_message_list).returns([])
    List.expects(:new).returns(list)

    job2 = Job.new :thread, :slug => 'example', :year => '2008', :month => '08'
    list = mock("list")
    list.expects(:cached_message_list).returns([])
    list.expects(:fresh_message_list).returns([])
    List.expects(:new).returns(list)

    t.expects(:get_job).times(3).returns(job1, job2, nil)
    t.run
  end

  def test_cache_work_empty
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    threadset = mock("threadset")
    threadset.expects(:collect).returns([])

    list = mock("list")
    list.expects(:cache_message_list).with("2007", "08", message_list)
    list.expects(:cache_thread_list).with("2007", "08", [])
    List.expects(:new).returns(list)

    Threader.new.cache_work slug, year, month, message_list, threadset
  end

  def test_cache_work
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']

    thread = mock("thread")
    thread.expects(:cache)
    thread.expects(:call_number).returns('00000000')
    thread.expects(:n_subject).returns('subject')
    thread.expects(:count).returns(1)

    threadset = mock("threadset")
    threadset.expects(:collect).yields(thread)

    list = mock("list")
    list.expects(:cache_message_list).with("2007", "08", message_list)
    list.expects(:cache_thread_list).with("2007", "08", [{ :call_number => "00000000", :subject => "subject", :messages => 1 }])
    List.expects(:new).returns(list)

    Threader.new.cache_work slug, year, month, message_list, threadset
  end

  private
  def new_threader
    t = Threader.new
    job = Job.new :thread, :slug => 'example', :year => '2008', :month => '08'
    t.expects(:get_job).returns(job, nil).at_least_once
    t
  end
end
