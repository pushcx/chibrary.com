require 'test_helper'

class ListTest < ActiveSupport::TestCase
  should "recognize invalid slugs that are too long" do
    assert_raises InvalidSlug do
      List.new '01234567890123456789x'
    end
  end

  should "recognize invalid slugs with non-alpha characters" do
    assert_raises InvalidSlug do
      List.new 'asdf#'
    end
  end

  context 'a list' do
    setup do
      @list = List.new 'slug'
    end

    should 'have a slug' do
      assert_equal 'slug', @list.slug
    end

    should 'return empty list when cache is empty' do
      $archive.expects(:[]).returns(nil)
      assert_equal [], @list.cached_message_list("2008", "01")
    end

    should 'fetch cached lists' do
      $archive.expects(:[]).returns(["1@example.com", "2@example.com"])
      assert_equal ["1@example.com", "2@example.com"], @list.cached_message_list("2008", "01")
    end

    should 'fetch an empty fresh message lists' do
      $archive.expects(:[]).returns(mock(:collect => []))
      assert_equal [], @list.fresh_message_list("2008", "01")
    end

    should 'fetch fresh message lists' do
      $archive.expects(:[]).returns(mock(:collect => ["1@example.com", "2@example.com"]))
      assert_equal ["1@example.com", "2@example.com"], @list.fresh_message_list("2008", "01")
    end

    should 'cache message lists' do
      $archive.expects(:[]=)
      @list.cache_message_list "2008", "01", ["1@example.com", "2@example.com"]
    end

    should 'fetch thread lists' do
      ThreadList.expects(:new).with('slug', '2008', '01')
      @list.thread_list("2008", "01")
    end

  end
end
