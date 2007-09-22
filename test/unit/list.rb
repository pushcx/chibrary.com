require File.dirname(__FILE__) + '/../test_helper'
require 'cachedhash'

class ListTest < Test::Unit::TestCase
  def test_slug
    list = List.new 'slug'
    assert_equal 'slug', list.slug
  end
end
