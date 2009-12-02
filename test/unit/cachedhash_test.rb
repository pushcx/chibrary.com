require 'test_helper'
require 'cachedhash'

class CachedHashTest < ActiveSupport::TestCase

  def test_find
    ch = CachedHash.new 'unit_test'
    assert_equal CachedHash, ch.class
    $archive.expects(:[]).with('unit_test/missing').raises(NotFound)
    assert_nil ch['missing']
    $archive.expects(:[]).with('unit_test/working').returns(mock(:chomp => 'working'))
    assert_equal 'working', ch['working']
  end

  def test_store
    ch = CachedHash.new 'unit_test'
    $archive.expects(:[]=).with('unit_test/key', 'value')
    ch['key'] = 'value'
    assert_equal 'value', ch['key']
  end
end
