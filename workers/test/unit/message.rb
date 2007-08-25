require File.dirname(__FILE__) + '/../test_helper'
require 'message'

class MessageTest < Test::Unit::TestCase
  fixtures :message 

  REPLY_SUBJECTS = ["Re: foo", "RE: foo", "RE[9]: foo", "re(9): foo", "re:foo", "re: Re: foo"]

  def test_subject_is_reply?
    REPLY_SUBJECTS.each do |subject|
      assert_equal true, Message.subject_is_reply?(subject)
    end
    assert_equal false, Message.subject_is_reply?("foo")
    assert_equal false, Message.subject_is_reply?("re-foo")
  end

  def test_normalize_subject
    REPLY_SUBJECTS.each do |subject|
      assert_equal 'foo', Message.normalize_subject(subject)
    end
    assert_equal 'foo', Message.normalize_subject("foo")
    assert_equal 're-foo', Message.normalize_subject("re-foo")
  end

  def test_good_message
    m = Message.new message(:good), 'test', '00000000'
    assert_equal m.class, Message

    assert_equal 'alice@example.com', m.from
    assert_equal 'Good message', m.subject
    assert_equal Time.gm(2006, 10, 24, 19, 47, 48), m.date
    assert m.date.utc?
    assert_equal ['grandparent@example.com', 'parent@example.com'], m.references
    assert_equal "goodid@example.com", m.message_id
    assert_equal "Message body.\n", m.body
  end

  def test_add_header
    m = Message.new message(:good), 'test', '00000000'
    m.add_header "X-Foo: x-foo"
    assert_match /^X-Foo: x-foo$/, m.headers
    assert_match /^X-ListLibrary-Added-Header: X-Foo$/, m.headers
    m.add_header "X-ListLibrary-Foo: x-foo"
    assert_match /^X-ListLibrary-Foo: x-foo$/, m.headers
    assert_no_match /^X-ListLibrary-Added-Header: X-ListLibrary-Foo$/, m.headers
  end

  def test_mailing_list_in_various_places
    [:good, :list_in_to, :list_in_cc, :list_in_bcc, :list_in_reply_to].each do |fixture|
      m = Message.new message(fixture), 'test', '00000000'
      expect_example_list m
      assert_equal "example", m.mailing_list
    end
  end

  def test_no_id
    m = Message.new message(:no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
  end

  def test_no_list
    m = Message.new message(:no_list), 'test', '00000000'
    m.addresses.expects(:[]).with('bob@example.com').returns(nil)
    assert_equal '_listlibrary_no_list', m.mailing_list
  end

  def test_no_list_and_no_id
    m = Message.new message(:no_list_and_no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
    m.addresses.expects(:[]).with('bob@example.com').at_least_once.returns(nil)
    assert_equal '_listlibrary_no_list', m.mailing_list
    key = 'list/_listlibrary_no_list/message/2006/10/00000000@generated-message-id.listlibrary.net'
    AWS::S3::S3Object.expects(:exists?).with(key, 'listlibrary_archive').returns(false)
    AWS::S3::S3Object.expects(:store).with(key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => m.from,
      :'x-amz-meta-subject'     => m.subject,
      :'x-amz-meta-references'  => m.references.join(' '),
      :'x-amz-meta-date'        => m.date,
      :'x-amz-meta-source'      => 'test',
      :'x-amz-meta-call_number' => '00000000'
    })
    m.store
  end

  def test_no_date
    m = Message.new message(:no_date), 'test', '00000000'
    assert (Time.now.utc - m.date) < 1
  end

  def test_wrong_format_date
    m = Message.new message(:wrong_format_date), 'test', '00000000'
    assert_equal Time.local(2007, 8, 7, 16, 6, 33), m.date
  end

  def test_malformed_date
    m = Message.new message(:malformed_date), 'test', '00000000'
    assert (Time.now.utc - m.date) < 1
  end

  def test_no_subject
    m = Message.new message(:no_subject), 'test', '00000000'
    assert_equal "", m.subject
  end

  def test_store_metadata
    m = Message.new message(:good), 'test', '00000000'
    key = 'list/example/message/2006/10/goodid@example.com'
    expect_example_list m
    AWS::S3::S3Object.expects(:exists?).with(key, 'listlibrary_archive').returns(false)
    expect_example_list m
    AWS::S3::S3Object.expects(:store).with(key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => 'alice@example.com',
      :'x-amz-meta-subject'     => 'Good message',
      :'x-amz-meta-references'  => 'grandparent@example.com parent@example.com',
      :'x-amz-meta-date'        => Time.parse('Tue Oct 24 19:47:48 UTC 2006'),
      :'x-amz-meta-source'      => 'test',
      :'x-amz-meta-call_number' => '00000000'
    })
    m.store
  end

  def test_generated_id
    m = Message.new message(:good), 'test', '00000000' # unused, just need the object
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.generated_id
  end

  def test_message_id
    m = Message.new message(:no_message_id), 'test', '00000000'
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_overwrite
    m = Message.new message(:good), 'test', '00000000'
    key = 'list/example/message/2006/10/goodid@example.com'
    expect_example_list m
    AWS::S3::S3Object.expects(:exists?).with(key, 'listlibrary_archive').returns(true)
    expect_example_list m
    assert_raises(RuntimeError, "overwrite attempted for listlibrary_archive #{key}") do
      m.store
    end
    m.overwrite = true
    expect_example_list m
    AWS::S3::S3Object.expects(:store).with(key, m.message, 'listlibrary_archive', {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => 'alice@example.com',
      :'x-amz-meta-subject'     => 'Good message',
      :'x-amz-meta-references'  => 'grandparent@example.com parent@example.com',
      :'x-amz-meta-date'        => Time.parse('Tue Oct 24 19:47:48 UTC 2006'),
      :'x-amz-meta-source'      => 'test',
      :'x-amz-meta-call_number' => '00000000'
    })
    m.store
  end

  private

  def expect_example_list m
    m.addresses.expects(:[]).with('example@list.example.com').returns('example')
  end
end
