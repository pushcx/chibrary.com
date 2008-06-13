require File.dirname(__FILE__) + '/../test_helper'
require 'list'

class ListTest < Test::Unit::TestCase
  def setup
    @list = List.new 'slug'
  end

  def test_slug
    assert_equal 'slug', @list.slug
  end

  def test_cached_message_list_empty
    $storage.expects(:load_yaml).returns(nil)
    assert_equal [], @list.cached_message_list("2008", "01")
  end

  def test_cached_message_list
    $storage.expects(:load_yaml).returns(["1@example.com", "2@example.com"])
    assert_equal ["1@example.com", "2@example.com"], @list.cached_message_list("2008", "01")
  end

  def test_fresh_message_list_empty
    $storage.expects(:list_keys)
    assert_equal [], @list.fresh_message_list("2008", "01")
  end

  def test_fresh_message_list
    $storage.expects(:list_keys).multiple_yields("1@example.com", "2@example.com")
    assert_equal ["1@example.com", "2@example.com"], @list.fresh_message_list("2008", "01")
  end

  def test_cache_message_list
    $storage.expects(:store_yaml)
    @list.cache_message_list "2008", "01", ["1@example.com", "2@example.com"]
  end

  def test_thread_list
    $storage.expects(:load_yaml).returns(["thread..."])
    assert_equal ["thread..."], @list.thread_list("2008", "01")
  end

  def test_cache_thread_list
    $storage.expects(:store_yaml)
    @list.cache_thread_list "2008", "01", ["1@example.com", "2@example.com"]
  end
end
