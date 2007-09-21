require File.dirname(__FILE__) + '/../test_helper'
require 'renderer'
require 'threading'
require 'message'

class ViewTest < Test::Unit::TestCase
  fixtures :message

  def test_compress_quotes
    YAML::load_file("test/fixtures/quoting.yaml").each do |name, quote|
      assert_equal quote['expect'], View::compress_quotes(View::h(quote['input'])), "testcase: #{name}"
    end
  end

  def test_message_body
    View.expects(:remove_footer)
    View.expects(:h)
    View.expects(:compress_quotes)
    View.message_body(stub_everything)
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

  def test_message_partial
    assert_equal 'message',            View::message_partial(Message.new(message(:good), 'test', '00000000'))
    assert_equal 'message_no_archive', View::message_partial(Message.new(message(:no_archive), 'test', '00000000'))
    assert_equal 'message_missing',    View::message_partial(nil)
    assert_equal 'message_missing',    View::message_partial(:fake_root)
  end

  def test_subject
    assert_equal 'subject',           View::subject(mock(:subject => 'subject'))
    assert_equal '<i>no subject</i>', View::subject(mock(:subject => ''))
  end
end

class RendererTest < Test::Unit::TestCase
  fixtures :message

  def setup
    $stdout.expects(:puts).at_least(0)
    @ssh = mock('ssh')
    @sftp = mock('sftp')
    @ssh.expects(:sftp).returns(mock(:connect => @sftp))
    Net::SSH.expects(:start).returns(@ssh)
  end

  def test_get_job
    r = Renderer.new

    AWS::S3::Bucket.expects(:objects).returns(['render_queue/example_list/2008/08'])
    assert_equal 'render_queue/example_list/2008/08', r.get_job

    AWS::S3::Bucket.expects(:objects).returns([])
    assert_equal nil, r.get_job
  end

  def test_render_list
    AWS::S3::Bucket.expects(:keylist).with('listlibrary_cachedhash', 'render/month/example/').returns([])
    AWS::S3::S3Object.expects(:exists?).with('render/index/example', 'listlibrary_cachedhash').returns(false)
    CachedHash.expects(:new).returns(stub_everything)
    List.expects(:new).with('example').returns('list')
    View.expects(:render).with(:page => 'list', :locals => {
      :title => 'example',
      :years => {},
      :list => 'list',
      :slug => 'example',
    }).returns('html')
    r = Renderer.new
    r.expects(:upload_page).with('example/index.html', 'html')
    r.render_list('example')
  end

  def test_month_previous_next_exist
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/06').returns(true)
    render_month.expects(:[]).with('2007/08').returns(true)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.month_previous_next "example", "2007", "07"
    assert_match /"\/example\/2007\/06"/, previous_link
    assert_match /"\/example\/2007\/08"/, next_link
  end

  def test_month_previous_next_none
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/06').returns(nil)
    render_month.expects(:[]).with('2007/08').returns(nil)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.month_previous_next "example", "2007", "07"
    assert_match /"\/example"/, previous_link
    assert_match /"\/example"/, next_link
  end

  def test_month_previous_next_previous_wraps
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2006/12').returns(true)
    render_month.expects(:[]).with('2007/02').returns(nil)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.month_previous_next "example", "2007", "01"
    assert_match /"\/example\/2006\/12"/, previous_link
    assert_match /"\/example"/, next_link
  end

  def test_month_previous_next_next_wraps
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/11').returns(nil)
    render_month.expects(:[]).with('2008/01').returns(true)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.month_previous_next "example", "2007", "12"
    assert_match /"\/example"/, previous_link
    assert_match /"\/example\/2008\/01"/, next_link
  end

  def test_render_month
    r = Renderer.new
    r.expects(:month_previous_next).with('example', '2007', '08').returns(['previous', 'next'])
    list = mock
    List.expects(:new).with('example').returns(list)
    ts = mock
    ThreadSet.expects(:month).with('example', '2007', '08').returns(ts)
    AWS::S3::S3Object.expects(:load_yaml).returns([{:messages => 1}, {:messages => 1}])
    View.expects(:render).with(:page => "month", :locals => {
      :title         => 'example 2007-08',
      :threadset     => ts,
      :inventory     => { :threads => 2, :messages => 2 },
      :previous_link => 'previous',
      :next_link     => 'next',
      :list          => list,
      :slug          => 'example',
      :year          => '2007',
      :month         => '08'
    }).returns("html")
    r.expects(:upload_page).with("example/2007/08/index.html", "html")
    r.render_month "example", "2007", "08"
  end

  def test_thread_previous_next_in_month
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/07').returns([
      { :call_number => '00000001', :subject => "foo", :messages => 3 },
      { :call_number => '00000002', :subject => "bar", :messages => 3 },
      { :call_number => '00000003', :subject => "baz", :messages => 3  },
    ].to_yaml)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.thread_previous_next "example", "2007", "07", "00000002"
    assert_match /"\/example\/2007\/07\/00000001"/, previous_link
    assert_match /"\/example\/2007\/07\/00000003"/, next_link
  end

  def test_thread_previous_next_none
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/07').returns([
      { :call_number => '00000002', :subject => "bar"},
    ].to_yaml)
    render_month.expects(:[]).with('2007/06').returns(nil)
    render_month.expects(:[]).with('2007/08').returns(nil)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.thread_previous_next "example", "2007", "07", "00000002"
    assert_match /archive/, previous_link
    assert_match /class="none"/, previous_link
    assert_match /archive/, next_link
    assert_match /class="none"/, next_link
  end

  def test_thread_previous_next_wraps
    r = Renderer.new
    render_month = mock
    render_month.expects(:[]).with('2007/07').returns([ { :call_number => '00000002', :subject => "bar", :messages => 3 } ].to_yaml)
    render_month.expects(:[]).with('2007/06').returns([ { :call_number => '00000001', :subject => "foo", :messages => 3 } ].to_yaml)
    render_month.expects(:[]).with('2007/08').returns([ { :call_number => '00000003', :subject => "baz", :messages => 3 } ].to_yaml)
    CachedHash.expects(:new).with('render/month/example').returns(render_month)
    previous_link, next_link = r.thread_previous_next "example", "2007", "07", "00000002"
    assert_match /"\/example\/2007\/06\/00000001"/, previous_link
    assert_match /"\/example\/2007\/08\/00000003"/, next_link
  end

  def _test_render_thread
    r = Renderer.new
    list = mock
    List.expects(:new).with('example').returns(list)
    thread = mock(:subject => 'thread')
    AWS::S3::S3Object.expects(:load_yaml).with("list/example/thread/2007/08/00000000").returns(thread)
    View.expects(:render).with(:page => "thread", :locals => {
      :title  => 'thread (example 2007-08)',
      :thread => thread,
      :list   => list,
      :slug   => 'example',
      :year   => '2007',
      :month => '08'
    }).returns("html")
    r.expects(:upload_page).with("example/2007/08/00000000", "html")
    r.render_thread "example", "2007", "08", "00000000"
  end

  def test_delete_thread
    process = mock('process')
    process.expects(:popen3).with("/bin/rm -f listlibrary.net/example/2007/08/00000000")
    @ssh.expects(:process).returns(process).at_least_once()
    Renderer.new.delete_thread "example", "2007", "08", "00000000"
  end

  def test_run_empty
    CachedHash.expects(:new).returns(mock)
    r = Renderer.new
    r.expects(:get_job).returns(nil)
    r.run
  end

  def test_run_list
    CachedHash.expects(:new).returns(mock)
    r = Renderer.new
    r.expects(:get_job).times(2).returns(mock(:key => "render_queue/example", :delete => nil), nil)
    r.expects(:render_list).with("example")
    r.run
  end

  def test_run_month
    render_queue = mock
    render_queue.expects(:[]=).with("example", '')
    CachedHash.expects(:new).returns(render_queue)
    r = Renderer.new
    r.expects(:get_job).times(2).returns(mock(:key => "render_queue/example/2007/08", :delete => nil), nil)
    r.expects(:render_month).with("example", "2007", "08")
    r.run
  end

  def test_run_thread_render
    render_queue = mock
    render_queue.expects(:[]=).with("example/2007/08", '')
    CachedHash.expects(:new).returns(render_queue)
    r = Renderer.new
    r.expects(:get_job).times(2).returns(mock(:key => "render_queue/example/2007/08/00000000", :delete => nil), nil)
    AWS::S3::S3Object.expects(:exists?).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(true)
    r.expects(:render_thread).with("example", "2007", "08", "00000000")
    r.run
  end

  def test_run_thread_delete
    render_queue = mock
    render_queue.expects(:[]=).with("example/2007/08", '')
    CachedHash.expects(:new).returns(render_queue)
    r = Renderer.new
    r.expects(:get_job).times(2).returns(mock(:key => "render_queue/example/2007/08/00000000", :delete => nil), nil)
    AWS::S3::S3Object.expects(:exists?).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(false)
    r.expects(:delete_thread).with("example", "2007", "08", "00000000")
    r.run
  end

  def test_upload_page
    @sftp.expects(:open_handle).yields(stub_everything)
    @sftp.expects(:write)
    @sftp.expects(:fsetstat)
    process = mock('process')
    process.expects(:popen3).at_least_once()
    @ssh.expects(:process).returns(process).at_least_once()

    r = Renderer.new
    r.upload_page "path/to/filename", "str"
  end
end
