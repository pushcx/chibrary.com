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
    t.run
  end

  def test_run_add_message
    t = new_threader
    AWS::S3::S3Object.expects(:load_yaml).returns(["1@example.com"])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns(["1@example.com", "2@example.com"])
    message = mock
    Message.expects(:new).with("2@example.com").returns(message)
    ts = mock
    ts.expects(:add_message).with(message)
    ThreadSet.expects(:month).returns(ts)

    t.expects(:cache_work)
    t.run
  end

  def test_run_multiple_jobs
    t = Threader.new

    # two empty jobs
    job1 = mock(:delete => nil)
    job1.expects(:key).returns('threader_queue/example/2008/07').at_least_once
    AWS::S3::S3Object.expects(:load_yaml).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/07/').returns([])

    job2 = mock(:delete => nil)
    job2.expects(:key).returns('threader_queue/example/2008/08').at_least_once
    AWS::S3::S3Object.expects(:load_yaml).returns([])
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])

    t.expects(:get_job).returns(job1, job2, nil).times(3)
    t.run
  end

  def test_cache_work_empty
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    threadset = mock
    threadset.expects(:threads).returns([])
    AWS::S3::S3Object.expects(:store).with("list/example/message_cache/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })
    t.inventory.expects(:[]=).with('example/2007/08', { :threads => 0, :messages => 0 }.to_yaml)

    t.cache_work slug, year, month, message_list, threadset
  end

  def test_cache_work_cached
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    AWS::S3::S3Object.expects(:store).with("list/example/message_cache/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })

    thread = mock
    thread.expects(:count).returns(1)
    thread.expects(:to_yaml).returns("yaml")
    thread.expects(:first).returns(mock(:call_number => '00000000'))
    threadset = mock
    threadset.expects(:threads).returns([thread])
    o = mock
    o.expects(:about).returns({ 'content-length' => "yaml".length })
    AWS::S3::S3Object.expects(:find).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(o)
    t.inventory.expects(:[]=).with('example/2007/08', { :threads => 1, :messages => 1 }.to_yaml)

    t.cache_work slug, year, month, message_list, threadset
  end

  def test_cache_work_uncached
    t = Threader.new
    slug, year, month = 'example', '2007', '08'

    message_list = ['1@example.com']
    AWS::S3::S3Object.expects(:store).with("list/example/message_cache/2007/08", message_list.to_yaml, 'listlibrary_archive', { :content_type => 'text/plain' })

    thread = mock
    thread.expects(:count).returns(1)
    thread.expects(:to_yaml).returns("yaml")
    thread.expects(:first).returns(mock(:call_number => '00000000'))
    threadset = mock
    threadset.expects(:threads).returns([thread])
    AWS::S3::S3Object.expects(:find).with("list/example/thread/2007/08/00000000", "listlibrary_archive").raises(RuntimeError)
    t.render_queue.expects(:[]=).with('example/2007/08/00000000', '')
    t.inventory.expects(:[]=).with('example/2007/08', { :threads => 1, :messages => 1 }.to_yaml)
    AWS::S3::S3Object.expects(:store).with('list/example/thread/2007/08/00000000', 'yaml', 'listlibrary_archive', {:content_type => 'text/plain'})

    t.cache_work slug, year, month, message_list, threadset
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
