require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  fixtures :message

  def setup
    addresses = mock('addresses')
    addresses.expects(:[]).at_least(0).returns('example')
    addresses.expects(:[]).with('bob@example.com').at_least(0).returns(nil)
    CachedHash.expects(:new).with('list_address').at_least(0).returns(addresses)
  end


  it 'load saved messages' do
    m = Message.new message(:good), 'test', '00000000'
    $archive.expects(:[]).with('/path/to/message').returns(m)
    m = Message.new '/path/to/message', 'test', '00000000'
    assert_equal message(:good), m.message
    expect(@m.subject_is_reply?).to be_false
  end

  should 'access fields in messages' do
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

  should 'catch when someone replies to start a new thread' do
    good = Message.new message(:good), 'test', '00000000'
    lazy_reply = Message.new message(:lazy_reply), 'test', '00000000'
    assert lazy_reply.likely_lazy_reply_to?(good)
  end

  should 'generate ids for messages without' do
    m = Message.new message(:no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
  end

  should 'have a default when a message has no recognized list' do
    expect_list 'bob@example.com', nil
    m = Message.new message(:no_list), 'test', '00000000'
    assert_equal '_listlibrary_no_list', m.slug
  end

  should 'handle messages without an id or a list' do
    m = Message.new message(:no_list_and_no_id), 'test', '00000000'
    assert_equal "00000000@generated-message-id.listlibrary.net", m.message_id
    assert_equal '_listlibrary_no_list', m.slug
    key = 'list/_listlibrary_no_list/message/2006/10/00000000@generated-message-id.listlibrary.net'
    $archive.expects(:has_key?).with(key).returns(false)
    $archive.expects(:[]=).with(key, m)
    m.store
  end

  should 'store messages' do
    m = Message.new message(:good), 'test', '00000000'
    key = 'list/example/message/2006/10/goodid@example.com'
    $archive.expects(:has_key?).with(key).returns(false)
    $archive.expects(:[]=).with(key, m)
    m.store
  end

  should 'raise errors when you attempt to overwrite' do
    m = Message.new message(:good), 'test', '00000000'
    assert_equal :error, m.overwrite
    $archive.expects(:has_key?).with(m.key).returns(true)
    assert_raises(RuntimeError, "overwrite attempted for listlibrary_archive #{m.key}") do
      m.store
    end
  end

  should 'overwrite when requested' do
    m = Message.new message(:good), 'test', '00000000'
    m.overwrite = :do
    $archive.expects(:[]=).with(m.key, m)
    m.store
  end

  should 'not overwrite when declined' do
    m = Message.new message(:good), 'test', '00000000'
    m.overwrite = :dont
    $archive.expects(:has_key?).with(m.key).returns(true)
    m.store
  end

  private

  def expect_list address, value
    addresses = mock('addresses2')
    addresses.expects(:[]).with(address).at_least_once.returns(value)
    CachedHash.expects(:new).with('list_address').returns(addresses)
  end
end
