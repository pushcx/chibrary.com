require 'test_helper'

class IntegerTest < ActiveSupport::TestCase
  should 'convert integers to base 64' do
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


class FilerTest < ActiveSupport::TestCase
  fixtures :message

  should 'not work unless subclassed' do
    f = Filer.new(0, 0)
    assert_raises(RuntimeError, /subclass/) do
      f.acquire
    end
  end

  context 'filers' do
    setup do
      # Many tests would otherwise cause the Filer to print its normal output
      $stdout.expects(:puts).at_least(0)
    end

    should 'store messages' do
      message = mock('message', :store => true, :key => "list/example_list/message/2006/10/goodid@example.com")
      message.expects(:slug).at_least_once.returns("example_list")
      message.expects(:date).times(2).returns( mock(:year => 2006, :month => 10) )
      Message.expects(:new).returns(message)

      f = Filer.new(0, 0)
      f.store message(:good)
      assert_equal 1, f.message_count
      assert_equal({ 'example_list' => [[2006, 10]] }, f.mailing_lists)
    end

    should 'handle storage failures' do
      message = mock('message')
      message.expects(:store).raises(RuntimeError, "something bad happened")
      Message.expects(:new).returns(message)
      $archive.expects(:[]=) # the error store

      f = Filer.new(0, 0)
      f.store message(:good)
      assert_equal 1, f.message_count
      assert_equal({}, f.mailing_lists)
    end

    should 'run cleanly when there are no messages' do
      # no messages
      f = Filer.new(0, 0)
      f.expects(:setup)
      f.expects(:acquire)
      f.expects(:queue_threader)
      f.expects(:teardown)
      f.sequences.expects(:[]=).with("0/#{Process.pid}", 0)
      f.run
    end

    class TestRunFiler < Filer
      def store message, overwrite ; @sequence += 1 ; end
    end
    should 'run' do
      f = TestRunFiler.new(0, 0)
      f.expects(:setup)
      f.expects(:acquire).yields("message", nil)
      f.expects(:queue_threader)
      f.expects(:teardown)
      f.sequences.expects(:[]=).with("0/#{Process.pid}", 1)
      f.run
    end

    should 'queue the threader' do
      f = Filer.new(0, 0)
      f.mailing_lists = { 'example_list' => [[2007, 8], [2007, 9]] }
      q = mock("thread queue")
      Queue.expects(:new).with(:thread).returns(q)
      q.expects(:add).with(:slug => "example_list", :year => 2007, :month => "08")
      q.expects(:add).with(:slug => "example_list", :year => 2007, :month => "09")
      f.queue_threader
    end

    should 'handle sequence exhaustion' do
      # exception should be raised on any attempt to generate an invalid call number
      f = Filer.new(0, (2 ** 20 + 1))
      assert_raises SequenceExhausted do
        f.call_number
      end

      # and also immediately after the last message safely read
      f = Filer.new(0, (2 ** 20))
      f.expects(:setup)
      f.expects(:acquire).yields(:message, nil)
      f.expects(:store).with(:message, nil).raises(SequenceExhausted, "sequence exhausted")
      f.sequences.expects(:[]=).with("0/#{Process.pid}", 2 ** 20)
      assert_raises SequenceExhausted do
        f.run
      end
    end

    should 'handle store() double failure' do
      Message.expects(:new).raises(RuntimeError, "Primary Error")
      $archive.expects(:[]=).raises(RuntimeError, "Secondary Error")

      rc = mock("remote connection")
      RemoteConnection.expects(:new).returns(rc)
      rc.expects(:upload_file)

      f = Filer.new(0, 0)
      f.expects(:release)
      f.store "mail"
    end

  end
end
