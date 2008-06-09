require File.dirname(__FILE__) + '/../test_helper'
require 'stdlib'


class EnumerableTest < Test::Unit::TestCase
  def test_sum
    assert_equal 3, [1, 2].sum
    assert_equal -1, [1, -2].sum
    assert_equal 0, [].sum
  end
end
