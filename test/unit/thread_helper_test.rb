require File.dirname(__FILE__) + '/../test_helper'

class ThreadHelperTest < ActionView::TestCase
  include ApplicationHelper
  include ThreadHelper
  fixtures :message

  should "format message bodies" do
    # This is kind of a dumb brittle test
    self.expects(:remove_footer).returns("body text")
    self.expects(:f).returns("body text")
    self.expects(:compress_quotes).returns("body text")
    message_body(stub(:slug => 'example', :body => "body text"))
  end

  should "remove footers" do
    body   = "body text\n"
    footer = "\n---\nmailing list footer"
    List.expects(:new).returns(mock(:[] => footer))

    str = remove_footer(body + footer, 'slug')
    assert_equal body.strip, str
  end

  should "compress quotes" do
    filename = File.join(File.dirname(__FILE__), '..', 'fixture', "quoting.yaml")
    YAML::load_file(filename).each do |name, quote|
      assert_equal quote['expect'], compress_quotes(f(quote['input'])), "testcase: #{name}"
    end
  end

  should "render messages" do
    mock_message = mock('message', :no_archive => false )

    used_container = mock("used container", :empty? => false, :root? => true, :children => [])
    used_container.expects(:message).returns(mock_message).times(2)

    self.expects(:render).with(:partial => 'message', :locals => { :message => mock_message, :parent => nil, :children => [] })
    container_partial(used_container)
  end

  should "render missing messages" do
    empty_container = mock(:empty? => true)
    self.expects(:render).with(:partial => 'message_missing')
    container_partial(empty_container)
  end

  should "render no_archive messages" do
    empty_container = mock(:empty? => false, :message => mock(:no_archive => true))
    self.expects(:render).with(:partial => 'message_no_archive')
    container_partial(empty_container)
  end
end
