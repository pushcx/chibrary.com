require File.dirname(__FILE__) + '/../test_helper'
require 'filer'

class FilerTest < Test::Unit::TestCase
  fixtures :message

  def test_acquire
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
      assert m.instance_of? Message
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

  def test_store_raises_exception
  end

  def test_run_unsubclassed
  end

  def test_run
  end

  def test_to_base64
  end

  def test_sequence_exhaustion
  end

end
