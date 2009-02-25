require File.dirname(__FILE__) + '/../test_helper'
require 'list'

require 'thread_list'
class ThreadList
  attr_reader :threads, :call_numbers
  public :first_thread, :last_thread, :key, :thread_index_of, :bundle_thread
end

class ThreadListTest < Test::Unit::TestCase
  def setup
  end

  def test_thread_list_new
    $archive.expects(:[]).raises(NotFound)
    tl = ThreadList.new 'example', '2009', '01'
    assert_equal [], tl.threads
    assert_equal({}, tl.call_numbers)
  end

  def test_thread_list_load
    tl = empty_thread_list
    assert_equal [], tl.threads
    assert_equal({}, tl.call_numbers)
  end

  def test_add_thread
    thread = mock('thread', :call_number => '00000000', :n_subject => 'subject', :count => '1')
    container = mock('container', :empty? => false, :call_number => '00000000')
    thread.expects(:each).yields(container)
    tl = empty_thread_list
    tl.add_thread thread
    assert_equal [{:call_number => "00000000", :messages => "1", :subject => "subject"}], tl.threads
    assert_equal({'00000000' => '00000000'}, tl.call_numbers)
  end

  # yeah, test_thread_count and test_message_count are shitty, but the code is dead simple
  def test_thread_count
    tl = empty_thread_list
    assert_equal 0, tl.thread_count
  end

  def test_message_count
    tl = empty_thread_list
    assert_equal 0, tl.thread_count
  end

  def test_previous_thread_none
    $archive.expects(:[]).raises(NotFound)
    tl = two_thread_list
    assert_nil tl.previous_thread('first001')
  end

  def test_previous_thread
    tl = two_thread_list
    assert_equal({
      :slug        => "example",
      :year        => "2009",
      :month       => "01",
      :call_number => "first001",
      :subject     => "first thread",
    }, tl.previous_thread('second01'))
  end

  def test_previous_thread_first
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

  def test_next_thread_none
    $archive.expects(:[]).raises(NotFound)
    tl = two_thread_list
    assert_nil tl.next_thread('second01')
  end

  def test_next_thread
    tl = two_thread_list
    assert_equal({
      :slug        => "example",
      :year        => "2009",
      :month       => "01",
      :call_number => "second01",
      :subject     => "second thread",
    }, tl.next_thread('first001'))
  end

  def test_next_thread_last
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

  def test_redirect_does
    tl = simple_thread_list
    assert_equal '00000001', tl.redirect?('00000002')
  end

  def test_redirect_doesnt
    tl = simple_thread_list
    assert !tl.redirect?('00000001')
  end

  def test_store
    tl = simple_thread_list
    $archive.expects(:[]=).with(tl.key, { :threads => [{:messages => '2', :call_number => '00000001', :subject => 'subject'}], :call_numbers => {'00000001' => '00000001', '00000002' => '00000001'} })
    tl.store
  end

  def test_year_counts_none
    $archive.expects(:[]).with('list/example/thread_list').raises(NotFound)
    assert_equal [], ThreadList.year_counts('example')
  end

  def test_year_counts
    zdir = mock('zdir')
    zdir.expects(:each).yields( '2009/01' )
    $archive.expects(:[]).with('list/example/thread_list').returns(zdir)
    ThreadList.expects(:new).returns(mock('thread_list', :thread_count => 1, :message_count => 2))
    assert_equal [["2009", {"01" => { :threads => 1, :messages => 2 }}]], ThreadList.year_counts('example')
  end

  def test_key
    assert_equal 'list/example/thread_list/2009/01', simple_thread_list.key
  end

  def test_thread_index_of
    assert_equal 0, simple_thread_list.thread_index_of('00000001')
  end

  def test_thread_index_of_error
    assert_raises(RuntimeError, /not in ThreadList/) { empty_thread_list.thread_index_of '00000000' }
  end

  def test_bundle_thread_none
    tl = empty_thread_list
    tl.bundle_thread nil, '2009', '01'
  end

  def test_bundle_thread
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
