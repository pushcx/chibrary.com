require File.dirname(__FILE__) + '/../test_helper'
require 'aws'

class BucketTest < Test::Unit::TestCase

  def test_keylist
  end
end

class S3ObjectTest < Test::Unit::TestCase

  def test_load_cache
    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').returns('[1, 2]')
    assert_equal [1, 2], AWS::S3::S3Object.load_cache('key')

    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').raises(RuntimeError)
    assert_equal nil, AWS::S3::S3Object.load_cache('key')
  end
end
