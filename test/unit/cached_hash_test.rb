require 'test_helper'

class CachedHashTest < ActiveSupport::TestCase
  context 'a cachedhash instance' do
    setup do
      @ch = CachedHash.new 'unit_test'
    end
    
    should 'turn NotFound into nil' do
      $archive.expects(:[]).with('unit_test/missing').raises(NotFound)
      assert_nil @ch['missing']
    end

    should 'find keys' do
      $archive.expects(:[]).with('unit_test/working').returns(mock(:chomp => 'working'))
      assert_equal 'working', @ch['working']
    end

    should 'store' do
      $archive.expects(:[]=).with('unit_test/key', 'value')
      @ch['key'] = 'value'
      assert_equal 'value', @ch['key']
    end
  end
end
