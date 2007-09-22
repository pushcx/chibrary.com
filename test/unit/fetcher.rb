require File.dirname(__FILE__) + '/../test_helper'
require 'fetcher'

class FetcherTest < Test::Unit::TestCase

  def test_setup
    Net::POP3.expects(:new).returns(mock(
      :open_timeout= => nil,
      :start => nil,
      :n_mails => 0
    ))
    $stdout.expects(:puts)
    f = Fetcher.new(0, 0)
    f.setup
  end

  def test_setup_server_down
    Net::POP3.expects(:new).raises(Timeout::Error, "execution expired")
    f = Fetcher.new(0, 0)
    assert_raises(Timeout::Error, "execution expired") do
      f.setup
    end
  end

  def test_teardown
    f = Fetcher.new(0, 0)
    nil.expects(:finish)
    f.teardown
  end

  def test_acquire
    f = Fetcher.new(0, 0)
    nil.expects(:delete_all).yields(mock(:mail => "Test message"))
    f.acquire { |mail| assert_equal 'Test message', mail }
  end

  def test_source
    assert_equal 'subscription', Fetcher.new(0, 0).source
  end
end
