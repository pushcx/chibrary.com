require 'test_helper'
require 'fetcher'

class FetcherTest < ActiveSupport::TestCase
  def test_setup
    Net::POP3.expects(:new).returns(mock(
      :open_timeout= => nil,
      :read_timeout= => nil,
      :start => nil,
      :n_mails => 0
    ))
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

  def test_teardown_unstarted
    # Sometimes teardown gets called because the pop3 connection errored during
    # setup, so finish would error if it were called.
    f = Fetcher.new(0, 0)
    nil.expects(:started?).returns(false)
    f.teardown
  end

  def test_teardown_started
    f = Fetcher.new(0, 0)
    nil.expects(:started?).returns(true)
    nil.expects(:finish)
    f.teardown
  end

  def test_acquire
    f = Fetcher.new(0, 0)
    mail = mock("mail", :delete => true)
    mail.expects(:mail).at_least(1).returns("Test message")
    nil.expects(:block).yields(stub_everything)
    nil.expects(:n_mails).yields(0)
    nil.expects(:each_mail).yields(mail)
    f.acquire { |mail, overwrite| assert_equal 'Test message', mail }
  end

  def test_empty_mail # this is a POP error Dreamhost likes to pull
    f = Fetcher.new(0, 0)
    mail = mock("mail")
    mail.expects(:mail).returns(nil)
    f.expects(:sleep).at_least(0)
    nil.expects(:block).yields(stub_everything)
    nil.expects(:n_mails).yields(0)
    nil.expects(:each_mail).yields(mail)
    # expect it to be treated as a POP error
    f.expects(:teardown)
    f.acquire { |mail, overwrite| }
  end

  def test_pop_error
    f = Fetcher.new(0, 0)
    mail = mock("mail")
    mail.expects(:mail).raises(Net::POPError, "Something went terribly wrong")
    f.expects(:sleep).at_least(0)
    nil.expects(:block).yields(stub_everything)
    nil.expects(:n_mails).yields(0)
    nil.expects(:each_mail).yields(mail)
    f.expects(:teardown)
    f.acquire { |mail, overwrite| }
  end

  def test_sequence_exhaustion
    f = Fetcher.new(0, 2 ** 20)
    mail = mock("mail")
    mail.expects(:mail).at_least(1).returns("Test Message")
    nil.expects(:block).yields(stub_everything)
    nil.expects(:n_mails).yields(0)
    nil.expects(:each_mail).yields(mail)
    f.acquire { |mail, overwrite| f.store mail }
  end

  def test_source
    assert_equal 'subscription', Fetcher.new(0, 0).source
  end
end
