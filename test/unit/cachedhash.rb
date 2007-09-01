require File.dirname(__FILE__) + '/../test_helper'
require 'cachedhash'

class CachedHashTest < Test::Unit::TestCase

  def test_find
    ch = CachedHash.new 'unit_test'
    assert_equal CachedHash, ch.class
    AWS::S3::S3Object.expects(:find).with('unit_test/missing', 'listlibrary_cachedhash').raises(RuntimeError)
    assert_nil ch['missing']
    AWS::S3::S3Object.expects(:find).with('unit_test/working', 'listlibrary_cachedhash').returns(mock(:value => 'working'))
    assert_equal 'working', ch['working']
  end

  def test_store
    ch = CachedHash.new 'unit_test'
    AWS::S3::S3Object.expects(:store).with('unit_test/key', 'value', 'listlibrary_cachedhash', { :content_type => 'text/plain' })
    ch['key'] = 'value'
    assert_equal 'value', ch['key']
  end
end
