require File.dirname(__FILE__) + '/../test_helper'
require 'renderer'
require 'threading'
require 'message'

class RendererTest < Test::Unit::TestCase
  fixtures :message

  def setup
    $stdout.expects(:puts).at_least(0)
    @rc = mock('remote connection')
    RemoteConnection.expects(:new).returns(@rc)
    @queues = mock('queues')
    Queue.expects(:new).times(4).returns(@queues)
  end

  def test_get_job
    r = Renderer.new

    # empty queues
    @queues.expects(:next).times(4)
    assert_equal nil, r.get_job

    job = mock("job")
    @queues.expects(:next).returns(job)
    assert_equal job, r.get_job
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
    @rc.expects(:upload_file).with('example/index.html', 'html')
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
    @rc.expects(:upload_file).with("example/2007/08/index.html", "html")
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
    @rc.expects(:upload_file).with("example/2007/08/00000000", "html")
    r.render_thread "example", "2007", "08", "00000000"
  end

  def test_delete_thread
    @rc.expects(:command).with("/bin/rm -f listlibrary.net/example/2007/08/00000000")
    Renderer.new.delete_thread "example", "2007", "08", "00000000"
  end

  def test_run_empty
    r = Renderer.new
    r.expects(:get_job).returns(nil)
    r.run
  end

  def test_run_list
    r = Renderer.new
    job = Job.new :render_list, :slug => "example"
    r.expects(:get_job).times(2).returns(job, nil)
    r.expects(:render_list).with("example")
    r.run
  end

  def test_run_month
    r = Renderer.new
    job = Job.new :render_month, :slug => "example", :year => "2008", :month => "01"
    r.expects(:get_job).times(2).returns(job, nil)
    r.expects(:render_month).with("example", "2008", "01")
    r.run
  end

  def test_run_thread_render
    r = Renderer.new
    job = Job.new :render_thread, :slug => "example", :year => "2007", :month => "08", :call_number => "00000000"
    r.expects(:get_job).times(2).returns(job, nil)
    AWS::S3::S3Object.expects(:exists?).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(true)
    r.expects(:render_thread).with("example", "2007", "08", "00000000")
    r.run
  end

  def test_run_thread_delete
    r = Renderer.new
    job = Job.new :render_thread, :slug => "example", :year => "2007", :month => "08", :call_number => "00000000"
    r.expects(:get_job).times(2).returns(job, nil)
    AWS::S3::S3Object.expects(:exists?).with("list/example/thread/2007/08/00000000", "listlibrary_archive").returns(false)
    r.expects(:delete_thread).with("example", "2007", "08", "00000000")
    r.run
  end
end
