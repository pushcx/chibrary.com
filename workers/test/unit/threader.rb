require File.dirname(__FILE__) + '/../test_helper'
require 'threader'
require 'message'

class ThreaderTest < Test::Unit::TestCase
  fixtures :message

  def setup
    $stdout.expects(:puts).at_least(0)
  end

  def test_get_job
    t = Threader.new

    AWS::S3::Bucket.expects(:objects).returns(['threader_queue/example_list/2008/08'])
    assert_equal 'threader_queue/example_list/2008/08', t.get_job

    AWS::S3::Bucket.expects(:objects).returns([])
    assert_equal nil, t.get_job
  end

  def test_load_cache
    t = Threader.new

    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').returns('[1, 2]')
    assert_equal [1, 2], t.load_cache('key')

    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').raises(RuntimeError)
    assert_equal nil, t.load_cache('key')
  end

  def test_run_empty
    t = new_threader

    # no messages in cache or bucket
    t.expects(:load_cache).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])

    # threader should exit cleanly
    t.run
  end

  def test_run_removed
    t = new_threader

    # one message in cache, none in list
    t.expects(:load_cache).returns(["goodid@example.com"], mock)
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/thread/2008/08/').returns([])
    ts = mock
    ThreadSet.expects(:new).times(2).returns(mock, ts)

    t.expects(:cache_work).with('example', '2008', '08', [], ts)
    t.run
  end

  def test_run_add_message
    t = new_threader
    thread = mock
    t.expects(:load_cache).times(2).returns(["1@example.com"], thread)
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns(["1@example.com", "2@example.com"])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/thread/2008/08/').returns("key")
    ts = mock
    ts.expects(:add_thread).with(thread)
    message = mock
    Message.expects(:new).with("2@example.com").returns(message)
    ts.expects(:add_message).with(message)
    ThreadSet.expects(:new).returns(ts)

    t.expects(:cache_work)
    t.run
  end

  def test_run_multiple_jobs
    t = Threader.new

    # two empty jobs
    job1 = mock(:delete => nil)
    job1.expects(:key).returns('threader_queue/example/2008/07').at_least_once
    t.expects(:load_cache).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/07/').returns([])

    job2 = mock(:delete => nil)
    job2.expects(:key).returns('threader_queue/example/2008/08').at_least_once
    t.expects(:load_cache).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])

    t.expects(:get_job).returns(job1, job2, nil).times(3)
    t.run
  end

  private
  def new_threader
    t = Threader.new
    job = mock(:delete => nil)
    job.expects(:key).returns('threader_queue/example/2008/08').at_least_once
    t.expects(:get_job).returns(job, nil).at_least_once
    t
  end
end
