require File.dirname(__FILE__) + '/../test_helper'
require 'lib/time'

class TimeTest < Test::Unit::TestCase
  def test_plus_year
    [
      [1,  2008, 9],
      [-1, 2006, 9],
    ].each do |delta, year, month|
      time = base_time.plus_year(delta)
      assert_equal year,  time.year
      assert_equal month, time.month
    end
  end

  def test_plus_month
    [
      [1,  2007, 10],
      [-1, 2007, 8],
      [4,  2008, 1],
      [-9, 2006, 12],
    ].each do |delta, year, month|
      time = base_time.plus_month(delta)
      assert_equal year,  time.year
      assert_equal month, time.month
    end
  end

  def test_plus_day
    [
      [1,   2007, 9,  12],
      [-1,  2007, 9,  10],
      [20,  2007, 10, 1],
      [-11, 2007, 8,  31],
    ].each do |delta, year, month, day|
      time = base_time.plus_day(delta)
      assert_equal year,  time.year
      assert_equal month, time.month
      assert_equal day,   time.day
    end
  end

  private
  def base_time
    Time.utc(2007, 9, 11)
  end
end
