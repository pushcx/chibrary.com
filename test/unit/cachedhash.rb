require File.dirname(__FILE__) + '/../test_helper'
require 'cachedhash'

class CachedHashTest < Test::Unit::TestCase

  def test_find
    ch = CachedHash.new 'unit_test'
    assert_equal CachedHash, ch.class
    $storage.expects(:load_string).with('listlibrary_cachedhash', 'unit_test/missing').raises(NotFound)
    assert_nil ch['missing']
    $storage.expects(:load_string).with('listlibrary_cachedhash', 'unit_test/working').returns(mock(:chomp => 'working'))
    assert_equal 'working', ch['working']
  end

  def test_store
    ch = CachedHash.new 'unit_test'
    $storage.expects(:store_string).with('listlibrary_cachedhash', 'unit_test/key', 'value')
    ch['key'] = 'value'
    assert_equal 'value', ch['key']
  end
end
