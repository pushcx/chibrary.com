require File.dirname(__FILE__) + '/../test_helper'
require 'message'

class MessageTest < Test::Unit::TestCase
  fixtures :message 

  def setup
  end

  def teardown
  end

  def test_good_message
    m = Message.new message(:good)
    assert_equal m.class, Message

    assert_equal 'alice@example.com', m.from
    assert_equal 'Good message', m.subject
    assert_equal Time.gm(2006, 10, 24, 19, 47, 48), m.date
    assert m.date.utc?
    assert_equal nil, m.in_reply_to
    assert_equal "goodid@example.com", m.message_id
  end

  def test_add_header
    m = Message.new message(:good)
    m.add_header "X-Foo: x-foo"
    assert_match /^X-Foo: x-foo$/, m.headers
    assert_match /^X-ListLibrary-Added-Header: X-Foo$/, m.headers
    m.add_header "X-ListLibrary-Foo: x-foo"
    assert_match /^X-ListLibrary-Foo: x-foo$/, m.headers
    assert_no_match /^X-ListLibrary-Added-Header: X-ListLibrary-Foo$/, m.headers
  end

  def test_generated_id
    m = Message.new message(:good) # unused, just need the object
  end

  def test_bucket
  end

  def test_no_list_and_no_id
  end

  def test_no_subject
  end

  def test_bad_date
  end

  def test_store_metadata
  end
end
