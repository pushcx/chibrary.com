require File.dirname(__FILE__) + '/../test_helper'
require 'threader'
require 'message'

class ThreaderTest < Test::Unit::TestCase
  fixtures :message

  def test_get_job
    t = Threader.new
    t.bucket = Mock.new

    t.bucket.expect(:find, ['listlibrary_cachedhash']) { OpenStruct.new :objects => ['threader_queue/example_list/2008/08'] }
    assert_equal 'threader_queue/example_list/2008/08', t.get_job
    t.bucket.expect(:find, ['listlibrary_cachedhash']) { OpenStruct.new :objects => [] }
    assert_equal nil, t.get_job
  end

  def test_load_cache
    t = Threader.new
    t.S3Object = Mock.new

    t.S3Object.expect(:find, ['key']){ OpenStruct.new :value => '[1, 2]' }
    assert_equal [1, 2], t.load_cache('key')

    t.S3Object.expect(:find, ['key']){ raise AWS::S3::NoSuchKey.new(nil, nil) }
    assert_equal [], t.load_cache('key')
  end

  class TestRunUncachedThreader < Threader
    def get_job ;
      if @loaded
        nil
      else
        @loaded = true
        OpenStruct.new :key => 'threader_queue/example/2008/08' ; end
      end
    def load_cache key ; [] ; end
  end
  def test_run_uncached
    t = TestRunUncachedThreader.new
    t.bucket   = Mock.new
    t.S3Object = Mock.new

    t.bucket.expect(:keylist, ['listlibrary_archive', 'list/example/message/2008/08/']){ [] }
    t.S3Object.expect(:store, ['list/example/threading/2008/08/message_cache', [].to_yaml])
    t.S3Object.expect(:store, ['list/example/threading/2008/08/threads',       [].to_yaml])
    t.run
  end
end
