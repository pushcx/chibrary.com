require File.dirname(__FILE__) + '/../test_helper'
require 'view'
require 'message'

class ViewTest < Test::Unit::TestCase
  fixtures :message

  def test_compress_quotes
    filename = File.join(File.dirname(__FILE__), '..', 'fixtures', "quoting.yaml")
    YAML::load_file(filename).each do |name, quote|
      assert_equal quote['expect'], View::compress_quotes(View::h(quote['input'])), "testcase: #{name}"
    end
  end

  def test_message_body
    View.expects(:remove_footer).returns("body text")
    View.expects(:h).returns("body text")
    View.expects(:compress_quotes).returns("body text")
    View.message_body(stub(:slug => 'example', :body => "body text"))
  end

  def test_remove_footer
    body   = "body text\n"
    footer = "\n---\nmailing list footer"
    m = mock
    m.expects(:slug).returns('slug')
    List.expects(:new).returns(mock(:[] => footer))
    m.expects(:body).returns(body + footer)

    str = View.message_body(m)
    assert_equal body.strip, str
  end

  def test_h
    [
      ['a user@a.com a',               'a user@a.com a'],
      ['a user@hp.com a',              'a user@hp...com a'],
      ['a user@ibm.com a',             'a user@ib...com a'],
      ['a user@example.com a',         'a user@ex...com a'],
      ['a user@example.co.uk a',       'a user@ex...uk a'],
      ['mailto:user@example.co.uk',    'mailto:user@ex...uk'],
      ["To: ruby-doc@ruby-lang.org\n", "To: ruby-doc@ru...org\n"],
      ["a@ibm.com b@ibm.com",          "a@ib...com b@ib...com"],

      ['http://aa.com',                '<a rel="nofollow" href="http://aa.com">http://aa.com</a>'],
      ["http://bb\a.com",              "<a rel=\"nofollow\" href=\"http://bb\a.com\">http://bb\a.com</a>"],
      ['http://cc.com?a=a',            '<a rel="nofollow" href="http://cc.com?a=a">http://cc.com?a=a</a>'],
      ['http://dd.com/"',              '<a rel="nofollow" href="http://dd.com/&quot;">http://dd.com/&quot;</a>'],
      ['telnet://ee.com',              '<a rel="nofollow" href="telnet://ee.com">telnet://ee.com</a>'],

      ['http://user:pass@ff.com/foo',  '<a rel="nofollow" href="http://user:pass@ff...com/foo">http://user:pass@ff...com/foo</a>'],
    ].each do |original, cleaned|
      assert_equal cleaned, View::h(original)
    end
  end

  def test_container_partial
    mock_message = mock('message', :no_archive => false, :key => 'key' )
    used_container = mock("used container", :empty? => false, :root? => true, :children => [])
    used_container.expects(:message).returns(mock_message).times(2)
    mock_created_message = mock("created message")
    Message.expects(:new).returns(mock_created_message)
    View.expects(:render).with(:partial => 'message', :locals => { :message => mock_created_message, :parent => nil, :children => [] })
    View::container_partial(used_container)

    empty_container = mock(:empty? => true)
    View.expects(:render).with(:partial => 'message_missing')
    View::container_partial(empty_container)

    empty_container = mock(:empty? => false, :message => mock(:no_archive => true))
    View.expects(:render).with(:partial => 'message_no_archive')
    View::container_partial(empty_container)
  end

  def test_subject
    assert_equal 'subject',           View::subject(mock(:n_subject => 'subject'))
    assert_equal '<i>no subject</i>', View::subject(mock(:n_subject => ''))
  end
end
