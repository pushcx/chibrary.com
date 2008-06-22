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
    $archive.expects(:[]).returns(nil)
    assert_equal [], @list.cached_message_list("2008", "01")
  end

  def test_cached_message_list
    $archive.expects(:[]).returns(["1@example.com", "2@example.com"])
    assert_equal ["1@example.com", "2@example.com"], @list.cached_message_list("2008", "01")
  end

  def test_fresh_message_list_empty
    $archive.expects(:[]).returns(mock(:collect => []))
    assert_equal [], @list.fresh_message_list("2008", "01")
  end

  def test_fresh_message_list
    $archive.expects(:[]).returns(mock(:collect => ["1@example.com", "2@example.com"]))
    assert_equal ["1@example.com", "2@example.com"], @list.fresh_message_list("2008", "01")
  end

  def test_cache_message_list
    $archive.expects(:[]=)
    @list.cache_message_list "2008", "01", ["1@example.com", "2@example.com"]
  end

  def test_thread_list
    $archive.expects(:[]).returns(["thread..."])
    assert_equal ["thread..."], @list.thread_list("2008", "01")
  end

  def test_cache_thread_list
    $archive.expects(:[]=)
    @list.cache_thread_list "2008", "01", ["1@example.com", "2@example.com"]
  end
end
