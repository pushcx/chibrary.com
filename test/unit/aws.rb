require File.dirname(__FILE__) + '/../test_helper'
require 'aws'

class BucketTest < Test::Unit::TestCase
  def test_keylist
  end
end

class S3ObjectTest < Test::Unit::TestCase
  def test_load_yaml
    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').returns('[1, 2]')
    assert_equal [1, 2], AWS::S3::S3Object.load_yaml('key')

    AWS::S3::S3Object.expects(:value).with('key', 'listlibrary_archive').raises(RuntimeError)
    assert_equal nil, AWS::S3::S3Object.load_yaml('key')
  end
end

class EnumerableTest < Test::Unit::TestCase
  def test_sum
    assert_equal 3, [1, 2].sum
    assert_equal -1, [1, -2].sum
    assert_equal 0, [].sum
  end

  def test_argfind
  end

  def test_argmin
  end
end
