require File.dirname(__FILE__) + '/../test_helper'
require 'message'

class MessageTest < Test::Unit::TestCase
  fixtures :message 

  def test_good_message
    m = Message.new message(:good), 0
    assert_equal m.class, Message

    assert_equal 'alice@example.com', m.from
    assert_equal 'Good message', m.subject
    assert_equal Time.gm(2006, 10, 24, 19, 47, 48), m.date
    assert m.date.utc?
    assert_equal nil, m.in_reply_to
    assert_equal "goodid@example.com", m.message_id
  end

  def test_add_header
    m = Message.new message(:good), 0
    m.add_header "X-Foo: x-foo"
    assert_match /^X-Foo: x-foo$/, m.headers
    assert_match /^X-ListLibrary-Added-Header: X-Foo$/, m.headers
    m.add_header "X-ListLibrary-Foo: x-foo"
    assert_match /^X-ListLibrary-Foo: x-foo$/, m.headers
    assert_no_match /^X-ListLibrary-Added-Header: X-ListLibrary-Foo$/, m.headers
  end

  def test_mailing_list_in_various_places
    [:good, :list_in_to, :list_in_cc, :list_in_reply_to].each do |fixture|
      m = Message.new message(fixture), 0
      expect_example_list m
      assert_equal "example", m.mailing_list
    end
  end

  def test_no_list_and_no_id
  end

  def test_no_list_and_no_id_and_no_date
  end

  def test_no_id_and_no_date
  end

  def test_no_date
  end

  def test_no_subject
    m = Message.new message(:no_subject), 0
    expect_example_list m
    assert_equal "", m.subject
  end

  def test_store_metadata
  end

  def test_generated_id
    m = Message.new message(:good), 0 # unused, just need the object
    expect_example_list m
    assert_equal "#{m.public_id}@generated-message-id.listlibrary.net", m.generated_id
  end

  def test_message_id
    m = Message.new message(:no_message_id), 0
    assert_equal "#{m.public_id}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_bucket
    m = Message.new message(:good), 0
    expect_example_list m
    assert_equal 'listlibrary_storage', m.bucket
    
    m = Message.new message(:no_list), 0
    m.addresses.expect(:'[]', ['bob@example.com']){ nil }
    assert_equal 'listlibrary_no_mailing_list', m.bucket
  end

  def test_public_id
    m = Message.new message(:good), 0
    m.public_id # just make sure it doesn't throw exceptions
  end

  def test_sequence
    assert_raises RuntimeError, "sequence #{2 ** 28 + 1} out of bounds" do
      m = Message.new message(:good), 2 ** 28 + 1
    end
  end

  private

  def expect_example_list m
    m.addresses.expect(:'[]', ['example@list.example.com']){ 'example' }
  end
end
