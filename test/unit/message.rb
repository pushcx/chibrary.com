require File.dirname(__FILE__) + '/../test_helper'
require 'message'

class MessageTest < Test::Unit::TestCase
  fixtures :message 

  REPLY_SUBJECTS = ["Re: foo", "RE: foo", "RE[9]: foo", "re(9): foo", "re:foo", "re: Re: foo", "fwd: foo", "Fwd: foo", "Fwd[14]: foo", "Re: Fwd: RE: fwd(3): foo", "fw: foo"]

  def setup
    addresses = mock('addresses')
    addresses.expects(:[]).at_least(0).returns('example')
    addresses.expects(:[]).with('bob@example.com').at_least(0).returns(nil)
    CachedHash.expects(:new).with('list_address').at_least(0).returns(addresses)
  end

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

  def test_new_saved
    m = Message.new message(:good), 'test', '00000000'
    $archive.expects(:[]).with('/path/to/message').returns(m)
    m = Message.new '/path/to/message', 'test', '00000000'
    assert_equal message(:good), m.message
  end

  def test_good_message
    m = Message.new message(:good), 'test', '00000000'
    assert_equal m.class, Message

    assert_equal 'Alice <alice@example.com>', m.from
    assert_equal 'Good message', m.subject
    assert_equal Time.gm(2006, 10, 24, 19, 47, 48), m.date
    assert m.date.utc?
    assert_equal ['grandparent@example.com', 'parent@example.com'], m.references
    assert_equal "goodid@example.com", m.message_id
    assert_equal "Message body.", m.body
    assert_equal false, m.no_archive
  end

  def test_likely_lazy_reply_to?
    good = Message.new message(:good), 'test', '00000000'
    lazy_reply = Message.new message(:lazy_reply), 'test', '00000000'
    assert lazy_reply.likely_lazy_reply_to?(good)
  end

  def test_formatting_message_id
    m = Message.new message(:formatting_message_id), 'test', '00000000'
    assert_equal "list/example/message/2008/01/id%m%d%s@example.com", m.key
  end

  class Message_test_from < Message ; public :load_from ; end
  def test_from
    m = Message_test_from.new message(:good), 'test', '00000000'
    [
      ['Bob Barker <bob@example.com>', 'Bob Barker <bob@example.com>'],
      ['"Bob Barker" <bob@example.com>', 'Bob Barker <bob@example.com>'],
    ].each do |original, cleaned|
      m.expects(:get_header).returns(original)
      m.load_from
      assert_equal cleaned, m.from
    end
  end

  def test_no_archive
    m = Message.new message(:no_archive), 'test', '00000000'
    assert m.no_archive
  end

  class Message_test_add_header < Message ; public :add_header, :headers ; end
  def test_add_header
    m = Message_test_add_header.new message(:good), 'test', '00000000'
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
      assert_equal "example", m.slug
    end
  end

  def test_real_slug
    expect_list 'linux-kernel@vger.kernel.org', 'linux-kernel'
    m = Message.new message(:real), 'test', '00000000'
    assert_equal 'linux-kernel', m.slug
  end

  def test_no_id
    m = Message.new message(:no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
  end

  def test_no_list
    expect_list 'bob@example.com', nil
    m = Message.new message(:no_list), 'test', '00000000'
    assert_equal '_listlibrary_no_list', m.slug
  end

  def test_no_list_and_no_id
    m = Message.new message(:no_list_and_no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
    assert_equal '_listlibrary_no_list', m.slug
    key = 'list/_listlibrary_no_list/message/2006/10/00000000@generated-message-id.listlibrary.net'
    $archive.expects(:has_key?).with(key).returns(false)
    $archive.expects(:[]=).with(key, m)
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
    $archive.expects(:has_key?).with(key).returns(false)
    $archive.expects(:[]=).with(key, m)
    m.store
  end

  def test_message_id
    m = Message.new message(:no_message_id), 'test', '00000000'
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_overwrite_error
    m = Message.new message(:good), 'test', '00000000'
    assert_equal :error, m.overwrite
    $archive.expects(:has_key?).with(m.key).returns(true)
    assert_raises(RuntimeError, "overwrite attempted for listlibrary_archive #{m.key}") do
      m.store
    end
  end

  def test_overwrite_do
    m = Message.new message(:good), 'test', '00000000'
    m.overwrite = :do
    $archive.expects(:[]=).with(m.key, m)
    m.store
  end

  def test_overwrite_dont
    m = Message.new message(:good), 'test', '00000000'
    m.overwrite = :dont
    $archive.expects(:has_key?).with(m.key).returns(true)
    m.store
  end

  def test_long_message_id
    # don't want long/ugly message_ids in the s3 keynames
    m = Message.new message(:long_message_id), 'test', '00000000'
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_invalid_message_id
    # RFC 2822, section 3.2.4 defines the valid characters
    m = Message.new message(:invalid_message_id), 'test', '00000000'
    assert_equal "#{m.call_number}@generated-message-id.listlibrary.net", m.message_id
  end

  def test_base64_encoded
    m = Message.new message(:base64_encoded), 'test', '00000000'
    assert m.from.include?("Pea, Botp")
    assert m.body.include?('put those in a batch file')
  end

  def test_mime_encoded
    m = Message.new message(:mime_encoded), 'test', '00000000'
    assert !m.body.include?('AppleMail')
    assert m.body.include?('Use the unix file')
  end

  def test_quoted_printable
    m = Message.new message(:quoted_printable), 'test', '00000000'
    assert !m.body.include?('=20')
  end

  def test_nested_mime
    m = Message.new message(:nested_mime), 'test', '00000000'
    assert !m.body.nil?
    assert m.body.include?('shoot their own')
  end

  def test_bad_content_type
    m = Message.new message(:bad_content_type), 'test', '00000000'
    assert !m.body.nil?
    assert m.body.include?('just heuristics')
  end

  def test_more_mime_fun
    m = Message.new message(:more_mime_fun), 'test', '00000000'
    assert !m.body.nil?
    assert m.body.include?('Later Christoph')
    assert !m.body.include?('=C3')
  end

  private

  def expect_list address, value
    addresses = mock('addresses2')
    addresses.expects(:[]).with(address).at_least_once.returns(value)
    CachedHash.expects(:new).with('list_address').returns(addresses)
  end
end
