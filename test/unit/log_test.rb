require 'test_helper'
require 'log'

class LoggerHashTest < ActiveSupport::TestCase
  def setup
    @log = Log.new 'worker'
  end
  def teardown ; @log = nil ; end

  def test_initialize
    assert_equal 'worker', @log.worker
  end

  def test_begin
    @log.expects(:log).with(:begin, 'message')
    @log.begin('key', 'message')
    assert_equal 'key', @log.key
  end

  def test_end
    @log.expects(:log).with(:begin, 'message')
    @log.begin('key', 'message')

    @log.expects(:log).with(:end, 'end message')
    @log.end('end message')
    assert @log.key.nil?
  end

  def test_block
    @log.expects(:begin).with('key', 'message')
    @log.expects(:end).with('end message')
    @log.block 'key', 'message' do |log|
      assert_not_equal log, @log # should get a new instance for sub-jobs
      "end message"
    end
  end

  def test_messaging
    [:error, :warning, :status].each do |status|
      @log.expects(:log).with(status, "message #{status}")
      @log.send(status, "message #{status}")
    end
  end
end
