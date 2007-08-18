require File.dirname(__FILE__) + '/../test_helper'
require 'threader'
require 'message'

class ThreaderTest < Test::Unit::TestCase
  fixtures :message

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

  def test_run_uncached
    $stdout.expects(:puts).at_least_once
    t = Threader.new
    job = mock(:delete => nil)
    job.expects(:key).returns('threader_queue/example/2008/08').at_least_once
    t.expects(:get_job).returns(job, nil).at_least_once
    t.expects(:load_cache).returns([])

    AWS::S3::Bucket.expects(:keylist).with('listlibrary_archive', 'list/example/message/2008/08/').returns([])
    # no caching as it won't think anything changed
    #AWS::S3::S3Object.expects(:store).with('list/example/threading/2008/08/message_cache', [].to_yaml)
    #AWS::S3::S3Object.expects(:store).with('list/example/threading/2008/08/threadset',     [].to_yaml)
    t.run
  end
end
