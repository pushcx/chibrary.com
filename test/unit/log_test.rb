require 'test_helper'

class LoggerHashTest < ActiveSupport::TestCase
  context 'a Log' do
    setup do
      @log = Log.new 'worker'
    end

    teardown do
      @log = nil
    end

    should 'be a worker' do
      assert_equal 'worker', @log.worker
    end

    should 'log a begin message' do
      @log.expects(:log).with(:begin, 'message')
      @log.begin('key', 'message')
      assert_equal 'key', @log.key
    end

    should 'log an end message' do
      @log.expects(:log).with(:begin, 'message')
      @log.begin('key', 'message')

      @log.expects(:log).with(:end, 'end message')
      @log.end('end message')
      assert @log.key.nil?
    end

    should 'log in a block' do
      @log.expects(:begin).with('key', 'message')
      @log.expects(:end).with('end message')
      @log.block 'key', 'message' do |log|
        assert_not_equal log, @log # should get a new instance for sub-jobs
        "end message"
      end
    end

    should 'log different kinds of messages' do
      [:error, :warning, :status].each do |status|
        @log.expects(:log).with(status, "message #{status}")
        @log.send(status, "message #{status}")
      end
    end

  end
end
