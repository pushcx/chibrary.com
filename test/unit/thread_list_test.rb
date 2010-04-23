require File.dirname(__FILE__) + '/../test_helper'

class ThreadList
  attr_reader :threads, :call_numbers
  public :first_thread, :last_thread, :key, :thread_index_of, :bundle_thread
end

class ThreadListTest < ActiveSupport::TestCase
  should 'start empty' do
    $archive.expects(:[]).raises(NotFound)
    tl = ThreadList.new 'example', '2009', '01'
    assert_equal [], tl.threads
    assert_equal({}, tl.call_numbers)
  end

  should 'load empty lists' do
    tl = empty_thread_list
    assert_equal [], tl.threads
    assert_equal({}, tl.call_numbers)
  end

  should 'add threads' do
    thread = mock('thread', :n_subject => 'subject', :count => '1')
    thread.expects(:call_number).at_least(0).returns('00000000')
    thread_root_container = mock('thread_root_container', :empty? => false, :call_number => '00000000')
    reply_container       = mock('reply_container', :empty? => false)
    reply_container.expects(:call_number).times(2).returns('00000001')
    thread.expects(:each).multiple_yields(thread_root_container, reply_container)
    tl = empty_thread_list
    tl.add_thread thread
    assert_equal [{:call_number => "00000000", :messages => "1", :subject => "subject"}], tl.threads
    # threads do not get a redirect to themselves - keeps redirect logic minimal
    assert_equal({'00000001' => '/example/2009/01/00000000'}, tl.call_numbers)
  end

  should 'redirect threads' do
    tl = empty_thread_list
    tl.add_redirected_thread ['00000000', '00000001'], '2009', '02'
    assert_equal({'00000000' => '/example/2009/02/00000000', '00000001' => '/example/2009/02/00000001'}, tl.call_numbers)
  end

  # yeah, these two tests are not comprehensive, but the code is dead simple
  should 'count threads' do
    tl = empty_thread_list
    assert_equal 0, tl.thread_count
  end
  should 'count messages' do
    tl = empty_thread_list
    assert_equal 0, tl.thread_count
  end

  context 'previous/next links' do
    should 'return nil when no previous thread' do
      $archive.expects(:[]).raises(NotFound)
      tl = two_thread_list
      assert_nil tl.previous_thread('first001')
    end

    should 'return data for previous thread' do
      tl = two_thread_list
      assert_equal({
        :slug        => "example",
        :year        => "2009",
        :month       => "01",
        :call_number => "first001",
        :subject     => "first thread",
      }, tl.previous_thread('second01'))
    end

    should 'link to thread in previous month' do
      tl = two_thread_list
      $archive.expects(:[]).returns({ :threads => [{:call_number => "prev0001", :messages => "1", :subject => "previous thread"}], :call_numbers => ['prev0001'] })
      assert_equal({
        :slug        => "example",
        :year        => 2008,
        :month       => "12",
        :call_number => "prev0001",
        :subject     => "previous thread",
      }, tl.previous_thread('first001'))
    end

    should 'return nil when no next thread' do
      $archive.expects(:[]).raises(NotFound)
      tl = two_thread_list
      assert_nil tl.next_thread('second01')
    end

    should 'return data for next thread' do
      tl = two_thread_list
      assert_equal({
        :slug        => "example",
        :year        => "2009",
        :month       => "01",
        :call_number => "second01",
        :subject     => "second thread",
      }, tl.next_thread('first001'))
    end

    should 'link to thread in next month' do
      tl = two_thread_list
      $archive.expects(:[]).returns({ :threads => [{:call_number => "next0001", :messages => "1", :subject => "next thread"}], :call_numbers => ['next0001'] })
      assert_equal({
        :slug        => "example",
        :year        => 2009,
        :month       => "02",
        :call_number => "next0001",
        :subject     => "next thread",
      }, tl.next_thread('second01'))
    end
  end

  should 'redirect to thread parent' do
    tl = simple_thread_list
    assert_equal '00000001', tl.redirect?('00000002')
  end

  should 'not redirect a thread parent' do
    tl = simple_thread_list
    assert !tl.redirect?('00000001')
  end

  should 'store to archive' do
    tl = simple_thread_list
    $archive.expects(:[]=).with(tl.key, { :threads => [{:messages => '2', :call_number => '00000001', :subject => 'subject'}], :call_numbers => {'00000001' => '00000001', '00000002' => '00000001'} })
    tl.store
  end

  should 'not error for a year count with no messages' do
    $archive.expects(:[]).with('list/example/thread_list').raises(NotFound)
    assert_equal [], ThreadList.year_counts('example')
  end

  should 'count messages for a year' do
    zdir = mock('zdir')
    zdir.expects(:each).yields( '2009/01' )
    $archive.expects(:[]).with('list/example/thread_list').returns(zdir)
    ThreadList.expects(:new).returns(mock('thread_list', :thread_count => 1, :message_count => 2))
    assert_equal [["2009", {"01" => { :threads => 1, :messages => 2 }}]], ThreadList.year_counts('example')
  end

  should 'generate a key based on slug, year, month' do
    assert_equal 'list/example/thread_list/2009/01', simple_thread_list.key
  end

  should 'find the index of threads by call number' do
    assert_equal 0, simple_thread_list.thread_index_of('00000001')
  end

  should 'raise an error when asked for the index of a non-existent thread' do
    assert_raises(RuntimeError, /not in ThreadList/) { empty_thread_list.thread_index_of '00000000' }
  end

  should 'return nil without threads' do
    tl = empty_thread_list
    assert_nil tl.bundle_thread nil, '2009', '01'
  end

  should 'bundle threads to a hash' do
    tl = simple_thread_list
    t = tl.bundle_thread({ :call_number => '00000001', :subject => 'subject' }, '2009', '01')
    assert_equal({
      :slug        => 'example',
      :year        => '2009',
      :month       => '01',
      :call_number => '00000001',
      :subject     => 'subject',
    }, t)
  end

  private
  def empty_thread_list
    $archive.expects(:[]).returns({ :threads => [], :call_numbers => {} })
    ThreadList.new 'example', '2009', '01'
  end

  def simple_thread_list
    $archive.expects(:[]).returns({
      :threads => [{:call_number=>"00000001", :messages => "2", :subject=>"subject"}],
      :call_numbers => { '00000001' => '00000001', '00000002' => '00000001' }
    })
    ThreadList.new 'example', '2009', '01'
  end

  def two_thread_list
    $archive.expects(:[]).returns({
      :threads => [
        { :call_number=>"first001", :messages => "2", :subject => "first thread" },
        { :call_number=>"second01", :messages => "7", :subject => "second thread" },
      ],
      :call_numbers => {
        'first001' => 'first001',
        'first002' => 'first001',
        'second01' => 'second01',
        'second02' => 'second01',
      }
    })
    ThreadList.new 'example', '2009', '01'
  end

  def add_thread_mocks
  end

end
