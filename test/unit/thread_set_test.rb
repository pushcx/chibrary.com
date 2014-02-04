require File.dirname(__FILE__) + '/../test_helper'
require 'permutation'

class ThreadSetTest < ThreadingTest
  def setup
    @ts = ThreadSet.new 'slug', '2009', '02'

    addresses = mock('addresses')
    addresses.expects(:[]).at_least(0).returns('example')
    CachedHash.expects(:new).with('list_address').at_least(0).returns(addresses)
  end
  def teardown
    @ts = nil
  end

  should 'hash thread subjects -> call number' do
    c1 = container_tree
    c1.each { |c| @ts << c.message unless c.empty? }
    expected_subjects = { "Threaded Message Fixtures" => c1 }
    @ts.collect # prime the cache
    assert_equal expected_subjects, @ts.send(:subjects)
  end

  # this is going to be a complex series of tests... but not yet
  should_eventually 'consider a thread_set with equal contents as =='

  should 'count messages' do
    # was failing to load Message-ID: <BAYC1-PASMTP14295C87CFA7B12CC8A613B4770@CEZ.ICE>
    ts = ThreadSet.new 'example', '2007', '12'
    rejoin_splits("2007-12").each do |mail|
      m = Message.new(mail, 'example', '00000000')
      ts << m
    end
    assert_equal %w{1196188048.22546.1223520349@webmail.messagingengine.com 4742D87E.7020701@casual-tempest.net}, ts.send(:root_set).collect(&:message_id)
    assert_equal 4, ts.message_count(false)
    # arguably, this could be 9, but dropping the empty container
    # 4742D87E.7020701@casual-tempest.net makes more sense than keeping it,
    # which is what differentiates between merging 'both dummies' and reparenting
    assert_equal 8, ts.message_count(true)
  end

  should 'rejoin split threads' do
    def ts year, month
      ts = ThreadSet.new 'example', year, month
      rejoin_splits("#{year}-#{month}").each do |mail|
        ts << Message.new(mail, 'example', '00000000')
      end
      ts.expects(:store).at_least(0)
      ts
    end
    nil.expects(:delete).at_least(0)
    ts11 = ts '2007', '11'
    ts12 = ts '2007', '12'
    ts01 = ts '2008', '01'
    assert_equal 13, ts11.message_count
    ts11.send(:retrieve_split_threads_from, ts12)
    assert_equal 0, ts12.message_count
    assert_equal 17, ts11.message_count
    ts11.send(:retrieve_split_threads_from, ts01)
    assert_equal 0, ts01.message_count
    assert_equal 24, ts11.message_count
  end

  should 'rejoin threads split by subject' do
    # on archives (eg. scraped mud-dev), there are no In-Reply-To/References headers
    def ts year, month
      ts = ThreadSet.new 'example', year, month
      rejoin_splits("#{year}-#{month}").each do |mail|
        ts << Message.new(mail, 'example', '00000000')
      end
      ts.expects(:store).at_least(0)
      ts
    end
    nil.expects(:delete).at_least(0)
    ts02 = ts '1997', '02'
    ts03 = ts '1997', '03'
    assert_equal 7, ts02.message_count
    assert_equal 5, ts03.message_count
    ts02.send(:retrieve_split_threads_from, ts03)
    assert_equal 11, ts02.message_count
    assert_equal 1, ts03.message_count
  end

  should 'remove a redirected thread' do
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    thread = @ts.containers['root@example.com']
    $archive.expects(:delete).with(thread.key)
    @ts.send(:redirect, thread, '2009', '02')
    assert @ts.containers.empty?
  end

  should 'redirect multiple threads' do
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    @ts << Message.new(threaded_message(:child), 'test', '0000root')
    thread = @ts.containers['root@example.com']
    $archive.expects(:delete)
    @ts.send(:redirect, thread, '2009', '02')
    assert @ts.containers.empty?
  end

  should 'be able to return the next/previous month' do
    Time.expects(:utc).with('2009', '02').returns(mock(:plus_month => mock('time', :year => 2009, :month => 1)))
    ts = mock('ThreadSet')
    ThreadSet.expects(:month).with('slug', 2009, '01').returns(ts)
    assert_equal ts, @ts.plus_month(-1)
  end

  class FakeMessage
    attr_accessor :message_id, :subject, :references
    def initialize message_id, subject, references ; @message_id = message_id ; @subject = subject ; @references = references ; end
    def date ; Time.now ; end
  end

#  should "RENAME ME: test caching" do
#    # create a vaguely real-shaped message tree
#    ts = ThreadSet.new
#    subjects = %w{foo bar baz quux lamb all makes human continued world}
#    100.downto(0) do |i|
#      ts.add_message FakeMessage.new(i.to_s, subjects[rand(subjects.size)], [(rand(400) / 4).to_s])
#    end
#    # dump it to YAML and reload it
#    ts = YAML::load(ts.to_yaml)
#    # add a few more messages for luck
#    120.downto(101) do |i|
#      ts.add_message FakeMessage.new(i.to_s, subjects[rand(subjects.size)], [(rand(100) / 4).to_s])
#    end
#    #ts.dump
#  end
end
