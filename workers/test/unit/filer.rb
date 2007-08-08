require File.dirname(__FILE__) + '/../test_helper'
require 'filer'

class FilerTest < Test::Unit::TestCase
  fixtures :message

  def test_acquire_unsubclassed
    f = Filer.new(0, 0)
    assert_raises(RuntimeError, /subclass/) do
      f.acquire
    end
  end

  def test_new_message
    f = Filer.new(0, 0)
    # move the initialize out of the way
    Message.class_eval do
      alias filer_initialize initialize
      def initialize *args ; end
    end
    begin
      m = f.new_message "foo"
      assert m.instance_of?(Message)
    ensure
      # don't break every later test using Message
      Message.class_eval do
        def initialize *args
          filer_initialize *args
        end
      end
    end
  end

  class TestStoreFiler < Filer
    def new_message mail
      # This is a bit hackish and brittle, but the test runs
      m = Mock.new
      m.expect(:store,        []){ true }
      m.expect(:mailing_list, []){ 'example_list' }
      m.expect(:mailing_list, []){ 'example_list' }
      m.expect(:mailing_list, []){ 'example_list' }
      m.expect(:date,         []){ OpenStruct.new 'year'  => 2006 }
      m.expect(:date,         []){ OpenStruct.new 'month' => 10 }
      m
    end
  end
  def test_store
    f = TestStoreFiler.new(0, 0)
    f.print_status = false
    f.store message(:good)
    assert_equal 1, f.message_count
  end

  class TestStoreFailsFiler < Filer
    def new_message mail
      # This is a bit hackish and brittle, but the test runs
      m = Mock.new
      m.expect(:store,        []){ raise "Something bad happens" }
      m.expect(:message,      []){ 'message' }
      m
    end
  end
  def test_store_fails
    f = TestStoreFailsFiler.new(0, 0)
    f.print_status = false
    f.S3Object = Mock.new
    f.S3Object.expect(:store)
    f.store message(:good)
    assert_equal 1, f.message_count
  end

  class TestRunFiler < Filer
    attr_reader :test_run_called

    alias test_run_initialize initialize
    def initialize *args
      @test_run_called = []
      test_run_initialize *args
    end

    def acquire
      @test_run_called << :acquire
      yield "Test message body"
    end

    # override store to skip mocking it out
    def store mail
      @test_run_called << :store
      true
    end

    def setup    ; @test_run_called << :setup    ; end
    def teardown ; @test_run_called << :teardown ; end
  end
  def test_run
    f = TestRunFiler.new(0, 0)
    f.print_status = false
    f.sequences.S3Object.expect(:store){ 0 }
    f.run
    assert_equal [:setup, :acquire, :store, :teardown], f.test_run_called
  end

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

  def test_sequence_exhaustion
  end

end
