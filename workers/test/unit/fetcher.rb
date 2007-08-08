require File.dirname(__FILE__) + '/../test_helper'
require 'fetcher'

class FetcherTest < Test::Unit::TestCase

  def test_setup
    f = Fetcher.new(0, 0)
    f.print_status = false
    f.POP3 = Mock.new
    f.POP3.expect(:new){ Mock.new true }
    f.setup
    assert !f.pop.called.select {|call| call if call[:method] == :start }.empty?
  end

  def test_setup_server_down
    f = Fetcher.new(0, 0)
    f.print_status = false
    f.POP3 = Mock.new
    f.POP3.expect(:new){ raise Timeout::Error.new("execution expired") }
    assert_raises(Timeout::Error, "execution expired") do
      f.setup
    end
  end

  def test_teardown
    f = Fetcher.new(0, 0)
    f.print_status = false
    f.pop = Mock.new
    f.pop.expect(:finish, [])
    f.teardown
  end

  def test_acquire
    f = Fetcher.new(0, 0)
    f.print_status = false
    f.pop = Mock.new
    f.pop.expect(:delete_all, []) { [OpenStruct.new('mail' => 'Test message')] }
    f.acquire { |mail| assert_equal 'Test message', mail }
  end

  def test_release
    # add when the fail store failure is in
  end
end
