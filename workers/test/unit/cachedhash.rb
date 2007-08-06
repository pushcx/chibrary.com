require File.dirname(__FILE__) + '/../test_helper'
require 'cachedhash'

class CachedHashTest < Test::Unit::TestCase

  def test_find
    ch = CachedHash.new 'unit_test'
    assert_equal CachedHash, ch.class
    ch.S3Object.expect(:find, ['unit_test/missing', 'listlibrary_cachedhash']){ raise AWS::S3::NoSuchKey.new('', '') }
    assert_nil ch['missing']
    ch.S3Object.expect(:find, ['unit_test/working', 'listlibrary_cachedhash']){ OpenStruct.new( 'value' => 'working' ) }
    assert_equal 'working', ch['working']
  end

  def test_store
    ch = CachedHash.new 'unit_test'
    ch.S3Object.expect(:store, ['unit_test/key', 'value', 'listlibrary_cachedhash', { :content_type => 'text/plain' }]){ OpenStruct.new( 'value' => 'value' ) }
    ch['key'] = 'value'
    assert_equal 'value', ch['key']
  end

  private

  def expect_example_list ch
    ch.S3Object.expect(:find, ['example@list.example.com', 'listlibrary_mailing_lists']){ OpenStruct.new( 'value' => 'example') }
  end
end
