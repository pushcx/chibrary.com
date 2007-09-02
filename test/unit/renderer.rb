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
  end

  def test_get_job
    r = Renderer.new

    AWS::S3::Bucket.expects(:objects).returns(['render_queue/example_list/2008/08'])
    assert_equal 'render_queue/example_list/2008/08', r.get_job

    AWS::S3::Bucket.expects(:objects).returns([])
    assert_equal nil, r.get_job
  end

  def test_render_list
  end

  def test_render_month
    r = Renderer.new
    list = mock
    List.expects(:new).with('example').returns(list)
    ts = mock
    ThreadSet.expects(:month).with('example', '2007', '08').returns(ts)
    inventory = mock
    AWS::S3::S3Object.expects(:load_yaml).returns(inventory)
    View.expects(:render).with(:page => "month", :locals => {
      :title     => 'example 2007-08',
      :threadset => ts,
      :inventory => inventory,
      :list      => list,
      :slug      => 'example',
      :year      => '2007',
      :month     => '08'
    }).returns("html")
    r.expects(:upload_page).with("example/2007/08/index.html", "html")
    r.render_month "example", "2007", "08"
  end

  def test_render_thread
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
    r = Renderer.new
    sftp = mock
    sftp.expects(:connect).yields(sftp)
    sftp.expects(:remove).with("listlibrary.net/example/2007/08/00000000")
    ssh = mock
    ssh.expects(:sftp).returns(sftp)
    r.expects(:ssh_connection).yields(ssh)
    r.delete_thread "example", "2007", "08", "00000000"
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
    handle = mock
    sftp = mock
    sftp.expects(:connect).yields(sftp)
    sftp.expects(:open_handle).yields(handle)
    sftp.expects(:mkdir).at_least_once()
    sftp.expects(:write).with(handle, "str")
    sftp.expects(:fsetstat).with(handle, { :permissions => 0644 })
    ssh = mock
    ssh.expects(:sftp).returns(sftp)
    ssh.expects(:process).returns(mock( :popen3 => nil)) # rename message
    r = Renderer.new
    r.expects(:ssh_connection).yields(ssh)
    r.upload_page "path/to/filename", "str"
  end

  def test_ssh_connection
    r = Renderer.new
    m = mock
    Net::SSH.expects(:start).yields(m)
    r.ssh_connection { |ssh| assert_equal m, ssh }
  end
end
