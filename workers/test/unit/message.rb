require File.dirname(__FILE__) + '/../test_helper'
require 'message'

class MessageTest < Test::Unit::TestCase
  fixtures :message 

  def test_good_message
    m = Message.new message(:good), '00000000'
    assert_equal m.class, Message

    assert_equal 'alice@example.com', m.from
    assert_equal 'Good message', m.subject
    assert_equal Time.gm(2006, 10, 24, 19, 47, 48), m.date
    assert m.date.utc?
    assert_equal nil, m.in_reply_to
    assert_equal "goodid@example.com", m.message_id
  end

  def test_add_header
    m = Message.new message(:good), '00000000'
    m.add_header "X-Foo: x-foo"
    assert_match /^X-Foo: x-foo$/, m.headers
    assert_match /^X-ListLibrary-Added-Header: X-Foo$/, m.headers
    m.add_header "X-ListLibrary-Foo: x-foo"
    assert_match /^X-ListLibrary-Foo: x-foo$/, m.headers
    assert_no_match /^X-ListLibrary-Added-Header: X-ListLibrary-Foo$/, m.headers
  end

  def test_mailing_list_in_various_places
    [:good, :list_in_to, :list_in_cc, :list_in_reply_to].each do |fixture|
      m = Message.new message(fixture), '00000000'
      expect_example_list m
      assert_equal "example", m.mailing_list
    end
  end

  def test_no_id
    m = Message.new message(:no_id), '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
  end

  def test_no_list
    m = Message.new message(:no_list), '00000000'
    m.addresses.expect(:'[]', ['bob@example.com']){ nil }
    assert_equal '_listlibrary_no_list', m.mailing_list
  end

  def test_no_list_and_no_id
    m = Message.new message(:no_list_and_no_id), '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
    m.addresses.expect(:'[]', ['bob@example.com']){ nil }
    assert_equal '_listlibrary_no_list', m.mailing_list
    key = '_listlibrary_no_list/2006/10/00000000@generated-message-id.listlibrary.net'
    m.addresses.expect(:'[]', ['bob@example.com']){ nil }
    m.S3Object.expect(:exists?, [key, 'listlibrary_archive']){ false }
    m.addresses.expect(:'[]', ['bob@example.com']){ nil }
    m.S3Object.expect(:store, [key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => m.from,
      :'x-amz-meta-subject'     => m.subject,
      :'x-amz-meta-in_reply_to' => m.in_reply_to,
      :'x-amz-meta-date'        => m.date,
      :'x-amz-meta-call_number' => '00000000'
    }]) {}
    m.store
  end

  def test_no_date
    m = Message.new message(:no_date), '00000000'
    assert (Time.now.utc - m.date) < 1
  end

  def test_wrong_format_date
    m = Message.new message(:wrong_format_date), '00000000'
    assert_equal Time.local(2007, 8, 7, 16, 6, 33), m.date
  end

  def test_malformed_date
    m = Message.new message(:malformed_date), '00000000'
    assert (Time.now.utc - m.date) < 1
  end

  def test_no_subject
    m = Message.new message(:no_subject), '00000000'
    assert_equal "", m.subject
  end

  def test_store_metadata
    m = Message.new message(:good), '00000000'
    key = 'example/2006/10/goodid@example.com'
    expect_example_list m
    m.S3Object.expect(:exists?, [key, 'listlibrary_archive']){ false }
    expect_example_list m
    m.S3Object.expect(:store, [key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => 'alice@example.com',
      :'x-amz-meta-subject'     => 'Good message',
      :'x-amz-meta-in_reply_to' => nil,
      :'x-amz-meta-date'        => Time.parse('Tue Oct 24 19:47:48 UTC 2006'),
      :'x-amz-meta-call_number' => '00000000'
    }]) {}
    m.store
  end

  def test_generated_id
    m = Message.new message(:good), '00000000' # unused, just need the object
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.generated_id
  end

  def test_message_id
    m = Message.new message(:no_message_id), '00000000'
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_overwrite
    m = Message.new message(:good), '00000000'
    key = 'example/2006/10/goodid@example.com'
    expect_example_list m
    m.S3Object.expect(:exists?, [key, 'listlibrary_archive']){ true }
    expect_example_list m
    assert_raises(RuntimeError, "overwrite attempted for listlibrary_archive example/2006/10/goodid@example.com") do
      m.store
    end
    m.overwrite = true
    expect_example_list m
    m.S3Object.expect(:store, [key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => 'alice@example.com',
      :'x-amz-meta-subject'     => 'Good message',
      :'x-amz-meta-in_reply_to' => nil,
      :'x-amz-meta-date'        => Time.parse('Tue Oct 24 19:47:48 UTC 2006'),
      :'x-amz-meta-call_number' => '00000000'
    }]) {}
    m.store
  end

  private

  def expect_example_list m
    m.addresses.expect(:'[]', ['example@list.example.com']){ 'example' }
  end
end
