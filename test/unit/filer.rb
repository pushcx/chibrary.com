require File.dirname(__FILE__) + '/../test_helper'
require 'filer'

class IntegerTest < Test::Unit::TestCase
  def test_to_base_64
    [
      [0, '00000000'], # base case
      [1, '00000001'], # add one
      [10, '0000000a'], # first lowercase letter
      [36, '0000000A'], # first uppercase letter
      [62, '0000000_'], # first _
      [63, '0000000-'], # last character: -
      [64, '00000010'], # second digit
      [2 ** 48 - 1, '--------'], # last number
    ].each do |from, to|
      assert_equal to, from.to_base_64
    end

    assert_raises(RuntimeError, "Unexpectedly large int converted") do
      (2 ** 48).to_base_64
    end
    assert_raises(RuntimeError, "No negative numbers") do
      (-1).to_base_64
    end
  end
end


class FilerTest < Test::Unit::TestCase
  fixtures :message

  def setup
    # Many tests would otherwise cause the Filer to print its normal output
    $stdout.expects(:puts).at_least(0)
  end


  def test_acquire_unsubclassed
    f = Filer.new(0, 0)
    assert_raises(RuntimeError, /subclass/) do
      f.acquire
    end
  end

  def test_store
    message = mock('message', :store => true, :key => "list/example_list/message/2006/10/goodid@example.com")
    message.expects(:slug).at_least_once.returns("example_list")
    message.expects(:date).times(2).returns( mock(:year => 2006, :month => 10) )
    Message.expects(:new).returns(message)

    f = Filer.new(0, 0)
    f.store message(:good)
    assert_equal 1, f.message_count
    assert_equal({ 'example_list' => [[2006, 10]] }, f.mailing_lists)
  end

  def test_store_fails
    message = mock('message')
    message.expects(:store).raises(RuntimeError, "something bad happened")
    Message.expects(:new).returns(message)
    AWS::S3::S3Object.expects(:store)

    f = Filer.new(0, 0)
    f.store message(:good)
    assert_equal 1, f.message_count
    assert_equal({}, f.mailing_lists)
  end

  class TestRunFiler < Filer
    def store message ; @sequence += 1 ; end
  end
  def test_run
    # no messages
    f = Filer.new(0, 0)
    f.expects(:setup)
    f.expects(:acquire)
    f.expects(:queue_threader)
    f.expects(:teardown)
    f.sequences.expects(:[]=).with("0/#{Process.pid}", 0)
    f.run

    f = TestRunFiler.new(0, 0)
    f.expects(:setup)
    f.expects(:acquire).yields("message")
    f.expects(:queue_threader)
    f.expects(:teardown)
    f.sequences.expects(:[]=).with("0/#{Process.pid}", 1)
    f.run
  end

  def test_queue_threader
    f = Filer.new(0, 0)
    f.mailing_lists = { 'example_list' => [[2007, 8], [2007, 9]] }
    f.thread_queue.expects(:'[]=').with('example_list/2007/08', '')
    f.thread_queue.expects(:'[]=').with('example_list/2007/09', '')
    f.queue_threader
  end

  def test_sequence_exhaustion
    # exception should be raised on any attempt to generate an invalid call number
    f = Filer.new(0, (2 ** 20 + 1))
    assert_raises SequenceExhausted do
      f.call_number
    end

    # and also immediately after the last message safely read
    f = Filer.new(0, (2 ** 20))
    f.expects(:setup)
    f.expects(:acquire).yields(:message)
    f.expects(:store).with(:message).raises(SequenceExhausted, "sequence exhausted")
    f.sequences.expects(:[]=).with("0/#{Process.pid}", 2 ** 20)
    assert_raises SequenceExhausted do
      f.run
    end
  end

  def test_store_double_failure
    Message.expects(:new).raises(RuntimeError, "Primary Error")
    AWS::S3::S3Object.expects(:store).raises(RuntimeError, "Secondary Error")

    rc = mock("remote connection")
    RemoteConnection.expects(:new).returns(rc)
    rc.expects(:upload_file)

    f = Filer.new(0, 0)
    f.expects(:release)
    f.store "mail"
  end

end
