require File.dirname(__FILE__) + '/../test_helper'
require 'permutation'

require 'threading'
require 'message'

class ThreadingTest < Test::Unit::TestCase
  fixtures [:threaded_message, :rejoin_splits]

  def test_dummy ; end

  private
  def container_tree
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
      c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
      c1.adopt c2
        c3 = Container.new Message.new(threaded_message(:grandchild), 'test', 'grndchld')
        c2.adopt c3
        c4 = Container.new "missing@example.com"
        c2.adopt c4
          c5 = Container.new Message.new(threaded_message(:orphan), 'test', '00orphan')
          c4.adopt c5
    c1
  end
end

class ContainerTest < ThreadingTest
  def setup
    addresses = mock('addresses')
    addresses.expects(:[]).at_least(0).returns('example')
    CachedHash.expects(:new).with('list_address').at_least(0).returns(addresses)
  end

  def test_initialize
    c = Container.new 'id@example.com'
    assert c.empty?
    assert c.orphan?
    assert c.children.empty?

    c = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    assert !c.empty?
  end

  def test_yaml
    c = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    assert !c.to_yaml.include?('Message body')
  end

  def test_equality
    c1  = Container.new '1@example.com'
    c1_ = Container.new '1@example.com'
    c2  = Container.new '2@example.com'
    assert c1 == c1_
    assert c1 != c2

    c1  = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c1_ = Container.new Message.new(threaded_message(:root), 'test', 'rootprim')
    c2  = Container.new Message.new(threaded_message(:child), 'test', '000child')
    assert c1 == c1_
    assert c1 != c2
  end

  def test_count
    assert_equal 0, Container.new('1@example.com').count
    assert_equal 1, Container.new(Message.new(threaded_message(:root), 'test', '0000root')).count
    assert_equal 4, container_tree.count
  end

  def test_depth
    c = container_tree
    assert_equal 0, c.depth
    assert_equal 1, c.children.first.depth
    assert_equal 2, c.children.first.children.first.depth
  end

  def test_empty?
    c = Container.new('root@example.com')
    assert c.empty?
    assert_nil c.message
    assert !Container.new(Message.new(threaded_message(:root), 'test', '0000root')).empty?
  end

  def test_likely_split_thread?_empty
    c = Container.new('root@example.com')
    assert c.likely_split_thread?
  end

  def test_likely_split_thread?_missing_parent
    c = Container.new Message.new(threaded_message(:child), 'test', '000child')
    assert c.likely_split_thread?
  end

  def test_to_s
    str = Container.new('root@example.com').to_s
    assert_match /root@example.com/, str
    assert_match /empty/, str

    str = Container.new(Message.new(threaded_message(:root), 'test', '0000root')).to_s
    assert_match /root@example.com/, str
    assert_no_match /empty/, str
  end

  def test_child_of?
    c1 = container_tree
    assert !c1.child_of?(c1.children.first)
    assert c1.children.first.child_of?(c1)
    assert c1.children.first.child_of?(c1.children.first)
    assert c1.children.first.children.first.child_of?(c1)
    assert !c1.child_of?(c1.children.first.children.first)
  end

  def test_root?
    container_tree.each do |container|
      if container.message_id == 'root@example.com'
        assert container.root?
      else
        assert !container.root?
      end
    end
  end

  def test_root
    c = container_tree
    c.each do |container|
      assert_equal c, container.root
    end
  end

  def test_each
    seen = container_tree.collect { |container|
      assert container.is_a?(Container)
      container.message_id
    }
    assert_equal %w{root child grandchild missing orphan}.collect { |i| "#{i}@example.com" }, seen
  end

  def test_effective_root
    # The effective root for the each container is itself, except c4's is c5.
    c1 = container_tree
    c1.each do |container|
      if container.message_id == 'missing@example.com'
        # ew here... maybe I should write a find_child?
        assert_equal c1.children.last.children.last.children.last, container.effective_root
      else
        assert_equal container, container.effective_root
      end
    end
  end

  def test_effective_field
    c1 = container_tree
    assert_equal 'Threaded Message Fixtures', c1.effective_field(:subject)
    # :missing should delegate cleanly to :orphan
    assert_equal 'Re: Re: Threaded Message Fixtures', c1.children.first.children.last.effective_field(:subject)
  end

  def test_cache_uncached
    c = container_tree
    $archive.expects(:[]).raises(NotFound)
    $archive.expects(:[]=)
    c.expects(:cache_snippet)
    c.cache
  end

  def test_cache_same
    c = container_tree
    c.expects(:to_yaml).returns("yaml".to_yaml)
    $archive.expects(:[]).returns("yaml")
    c.cache
  end

  def test_cache_different
    c = container_tree
    c.expects(:to_yaml).returns("yaml")
    $archive.expects(:[]).returns("old yaml")
    $archive.expects(:[]=)
    c.expects(:cache_snippet)
    c.cache
  end

  def test_cache_snippet
    c = Container.new ''
    body = ">The\nfirst\nfive\n\nunquoted\nnonblank\nlines"
    snippet = {
      :excerpt => "first five unquoted nonblank lines",
      :subject => 'subject',
      :url => '/slug/2009/02/00000000',
    }
    c.expects(:n_subject).returns(snippet[:subject])
    c.expects(:date).times(4).returns(Time.at(1234232107))
    c.expects(:call_number).returns('00000000')
    c.expects(:n_subject).returns('subject')
    c.expects(:effective_field).with(:slug).times(2).returns('slug')
    c.expects(:effective_field).with(:body).returns(body)
    $archive.expects(:[]=).with('snippet/homepage/8765767892', snippet)
    $archive.expects(:[]=).with('snippet/list/slug/8765767892', snippet)
    c.cache_snippet
  end

  def test_orphan
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c1.adopt c2
    
    c1.expects(:disown).with(c2)
    c2.orphan
    assert c2.orphan?
  end

  def test_disown
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c1.adopt c2

    c1.send(:disown, c2) # protected method, using .send to test
    assert c1.children.empty?
  end

  def test_parent=
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c2.send(:parent=, c1) # protected method, using .send to test
    assert !c2.orphan?
    assert_equal c1, c2.parent
  end

  def test_message=
    c = Container.new "root@example.com"
    m = Message.new(threaded_message(:root), 'test', '0000root')
    c.message = m
    assert_equal m, c.message

    assert_raises(RuntimeError, /message id/i) do
      c = Container.new "wrong@example.com"
      m = Message.new(threaded_message(:root), 'test', '0000root')
      c.message = m
    end
  end

  # Calls to adopt that would set up a cyclical graph should just be quietly
  # ignored. Because we're parenting based on possibly-malicious and often
  # incompetently-generated references, it's not an exceptional circumstance
  # the threader really cares to know about.
  def test_adopt_not_self
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c1.adopt c1
    assert c1.orphan?
    assert c1.children.empty?
  end
  def test_adopt_not_parent
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c1.adopt c2
    c1.adopt c2
    assert_equal c1, c2.parent
    assert c1.children.include?(c2)
    assert c1.root?
    assert c2.children.empty?
  end
  def test_adopt_not_parent
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c1.adopt c2
    c2.adopt c1
    assert_equal c1, c2.parent
    assert c1.children.include?(c2)
    assert c1.root?
    assert c2.children.empty?
  end

  def test_adopt
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')

    assert c1.children.empty?
    assert c2.orphan?
    c1.adopt c2
    assert_equal c1, c2.root
    assert_equal [c2], c1.children
    assert !c2.orphan?
  end

  def test_adopt_doesnt_reparent
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c3 = Container.new Message.new(threaded_message(:grandchild), 'test', 'grndchld')
    c1.adopt c2
    c3.adopt c2
    assert_equal c1, c2.parent
    assert c1.children.include?(c2)
    assert !c1.children.include?(c3)
    assert c3.children.empty?
  end

  def test_adopt_trusts_for_parenting
    c1 = Container.new Message.new(threaded_message(:root), 'test', '0000root')
    c2 = Container.new Message.new(threaded_message(:child), 'test', '000child')
    c3 = Container.new Message.new(threaded_message(:grandchild), 'test', 'grndchld')
    c1.adopt c3
    c2.adopt c3
    assert_equal c2, c3.parent
    assert c1.children.empty?
    assert c2.children.include?(c3)
  end

end

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

  def test_month_new
    ts = mock
    ThreadSet.expects(:new).returns(ts)
    $archive.expects(:has_key?).with("list/example/thread/2009/01").returns(false)
    assert_equal ts, ThreadSet.month('example', '2009', '01')
  end

  def test_month
    ts = mock
    ThreadSet.expects(:new).returns(ts)

    thread = mock("thread")
    thread.expects(:message_id).times(4).returns("id@example.com")
    thread.expects(:each).times(4).yields(thread)

    threads = mock("threads")
    threads.expects(:each).multiple_yields('a', 'b', 'c', 'd')
    threads.expects(:[]).times(4).returns(thread)

    $archive.expects(:has_key?).with("list/example/thread/2007/08").returns(true)
    $archive.expects(:[]).with("list/example/thread/2007/08").returns(threads)

    ts.expects(:containers).times(4).returns(stub_everything)
    assert_equal ts, ThreadSet.month('example', '2007', '08')
  end

  def test_subjects
    c1 = container_tree
    c1.each { |c| @ts << c.message unless c.empty? }
    expected_subjects = { "Threaded Message Fixtures" => c1 }
    @ts.collect # prime the cache
    assert_equal expected_subjects, @ts.send(:subjects)
  end

  def test_equality
    # OK, it's just too goddamned ugly to want to test
  end

  def test_root_set
    assert_equal [], @ts.send(:root_set) # private method, using .send to test

    @ts = ThreadSet.new 'slug', '2009', '02'
    c1 = container_tree
    c1.each { |c| @ts << c.message unless c.empty? }
    root_set = @ts.send(:root_set)
    assert_equal 1, root_set.length
    assert_equal c1, root_set.first
    assert_equal root_set, @ts.send(:root_set) # test caching
  end

  def test_append_doesnt_double_store
    m = Message.new(threaded_message(:root), 'test', '0000root')
    @ts << m
    @ts << m
    assert threads = @ts.collect { |c| c }
    assert_equal 1, threads.size
    assert_equal m, threads.first.message
  end

  def test_simple_append
    m1 = Message.new(threaded_message(:root), 'test', '0000root')
    m2 = Message.new(threaded_message(:child), 'test', '000child')
    @ts << m1
    @ts << m2
    assert threads = @ts.collect { |c| c }
    assert_equal 1, threads.size
    assert_equal m1, threads.first.message
    assert_equal 1, threads.first.children.size
    assert_equal m2, threads.first.children.first.message
  end

  def test_fill_in_empty_container
    # same as test_simple_append but in different order
    m1 = Message.new(threaded_message(:root), 'test', '0000root')
    m2 = Message.new(threaded_message(:child), 'test', '000child')
    @ts << m2
    @ts << m1
    assert threads = @ts.collect { |c| c }
    assert_equal 1, threads.size
    assert_equal m1, threads.first.message
    assert_equal 1, threads.first.children.size
    assert_equal m2, threads.first.children.first.message
  end

  def test_permutations
    # whatever the order of messages from the example container_tree, the output should be the same
    messages = [:root, :child, :grandchild, :orphan].collect { |sym| Message.new(threaded_message(sym), 'test', '00000000') }
    perm = Permutation.for(messages)
    previous = nil
    perm.each do |perm|
      ts = ThreadSet.new 'slug', '2009', '02'
      perm.project.each { |message| ts << message }
      assert_equal previous, ts if previous
      previous = ts
    end
  end

  def test_complex_threading
    messages = YAML::load_file( File.join(File.dirname(__FILE__), '..', 'fixtures', "complex_thread.yaml") )
    messages.each { |m| @ts << Message.new(m, 'test', '00000000') }

    # confirm that no extra threads are created or missed
    expected_threads = %w{1183313785.421818.119180@n2g2000hse.googlegroups.com 46B1E8B9.6040905@cesmail.net 20070803062022.GB17735@polycrystal.org 469096F0.2080203@atdot.net 46A605C1.6030806@sarion.co.jp e0a4c0830708060853y78c58fdcsb916086b098bf814@mail.gmail.com 46B76A46.1000902@davidflanagan.com 4e4a257e0708070124h273cbf52la918f07525d28c40@mail.gmail.com 51BF19F7-15F6-4399-956C-008CC1432D0D@grayproductions.net 4656BC23.5010201@ruby-lang.org 200707280246.l6S2k9Mi011192@ci.ruby-lang.org 20070808185938.GA16490@danisch.de 46BA305A.4030300@davidflanagan.com 46BA5403.4010307@davidflanagan.com 46BC70E8.8080002@qwest.com daff01530708122145i2cdaf470t6320c960308562e2@mail.gmail.com 46C00B17.5090202@sun.com 20070814090704.GA32034@uk.tiscali.com 20070814101715.GA9138@bart.bertram-scharpf.homelinux.com 20070814214858.GA23413@danisch.de d8a74af10708141459t7d12ceabla8b0f9ac875fe81f@mail.gmail.com 46C51F13.2070104@cesmail.net 335e48a90708180348w5304e0fcp98dd9aad304055b6@mail.gmail.com F58FE69873E2D5459B72C347DE15824116B61980CB@NA-EXMSG-C112.redmond.corp.microsoft.com 46CAFA7B.9060904@atdot.net d8a74af10708210846s6ccd7649u16ca78cdb308f68f@mail.gmail.com 20070822005417.GA53919@lizzy.catnook.local 46CBE1C2.7070109@davidflanagan.com 46CC5605.9050003@maven-group.org 46CC8548.3010802@davidflanagan.com 46CCE027.30307@dan42.com e3caf1460706051414x41ad8f69k7068d26a835fd232@mail.gmail.com F58FE69873E2D5459B72C347DE15824116B6199049@NA-EXMSG-C112.redmond.corp.microsoft.com 46CE0A81.1050205@qwest.com 4088e1c90708232328v4e2cd446xe6016b1f740a92a1@mail.gmail.com 46CF2040.2050504@davidflanagan.com 7d9a1f530708250122k43cdd24fo6f0cdc8efe972abb@mail.gmail.com 16956643-A0EE-47E7-BB4D-9FCCC5796FD0@segment7.net 20060718213611.65816A97001C@rubyforge.org 20070827222111.GA21576@bart.bertram-scharpf.homelinux.com 20070829164912.M60248@jena-stew.de 46D5D510.7060706@qwest.com 20070830123014.GA25287@uk.tiscali.com 7524A45A1A5B264FA4809E2156496CFBE72DBD@ITOMAE2KM01.AD.QINTRA.COM Pine.GSO.4.64.0708301844080.337@brains.eng.cse.dmu.ac.uk 20070830191148.GA8233@bart.bertram-scharpf.homelinux.com 46D7B697.1070201@davidflanagan.com 46D7BABE.60101@davidflanagan.com 46D84D65.2020604@sun.com}
    assert found_threads = @ts.collect(&:message_id)
    # check for missing threads
    assert_equal [], expected_threads - found_threads
    # check for extra threads
    assert_equal [], found_threads - expected_threads
    # check order
    assert_equal expected_threads, found_threads

    # confirm that all messages have proper parents
    expected_parents = "1183313785.421818.119180@n2g2000hse.googlegroups.com under nobody
      1183321232.853043.171940@q75g2000hsh.googlegroups.com under 1183313785.421818.119180@n2g2000hse.googlegroups.com
      200707160357.l6G3vBng012285@sharui.nakada.kanuma.tochigi.jp under 1183321232.853043.171940@q75g2000hsh.googlegroups.com
      1186016852.936524.8480@q75g2000hsh.googlegroups.com under 200707160357.l6G3vBng012285@sharui.nakada.kanuma.tochigi.jp
      20070802045226.012EBE032F@mail.bc9.jp under 1186016852.936524.8480@q75g2000hsh.googlegroups.com
      46B1E8B9.6040905@cesmail.net under nobody
      067A913C-55F9-408F-B655-B4D317D62F6A@grayproductions.net under 46B1E8B9.6040905@cesmail.net
      46B26E53.7040907@davidflanagan.com under 46B1E8B9.6040905@cesmail.net
      20070803062022.GB17735@polycrystal.org under nobody
      469096F0.2080203@atdot.net under nobody
      414772D6-5998-484B-869D-15B0464632D3@segment7.net under 469096F0.2080203@atdot.net
      469C7CE9.1040208@sarion.co.jp under 414772D6-5998-484B-869D-15B0464632D3@segment7.net
      80DAFD68-4AC5-4C24-A75E-048341A41D8F@segment7.net under 469C7CE9.1040208@sarion.co.jp
      469DCEA8.5020407@sarion.co.jp under 80DAFD68-4AC5-4C24-A75E-048341A41D8F@segment7.net
      46A6023C.20409@sarion.co.jp under 469DCEA8.5020407@sarion.co.jp
      46A8546A.9030604@sarion.co.jp under 46A6023C.20409@sarion.co.jp
      e3caf1460708031213v59675b20x4265a29f30a56c8@mail.gmail.com under 46A8546A.9030604@sarion.co.jp
      6EA8C021-6180-433C-9DAD-9BABE3571BC0@fallingsnow.net under e3caf1460708031213v59675b20x4265a29f30a56c8@mail.gmail.com
      B541D790-228E-4D4A-9518-8D067CAF0802@segment7.net under 6EA8C021-6180-433C-9DAD-9BABE3571BC0@fallingsnow.net
      D543C6E0-E19B-4803-BF9D-686C05224508@segment7.net under 46A6023C.20409@sarion.co.jp
      46A6C031.4060409@sarion.co.jp under D543C6E0-E19B-4803-BF9D-686C05224508@segment7.net
      46A6E9B4.5090607@ruby-lang.org under 46A6C031.4060409@sarion.co.jp
      AE6203AD-28C4-4373-AB79-D079A9A6D837@zenspider.com under 46A6E9B4.5090607@ruby-lang.org
      9e7db9110708041446o419511dek40ed083ab85a8b65@mail.gmail.com under AE6203AD-28C4-4373-AB79-D079A9A6D837@zenspider.com
      46A605C1.6030806@sarion.co.jp under nobody
      20070805133121.2d50ddb5.sheepman@sheepman.sakura.ne.jp under 46A605C1.6030806@sarion.co.jp
      e0a4c0830708060853y78c58fdcsb916086b098bf814@mail.gmail.com under nobody
      e0a4c0830708060903v3fa71396s88460ded5d0d8721@mail.gmail.com under e0a4c0830708060853y78c58fdcsb916086b098bf814@mail.gmail.com
      Pine.GSO.4.64.0708061718040.9740@brains.eng.cse.dmu.ac.uk under e0a4c0830708060903v3fa71396s88460ded5d0d8721@mail.gmail.com
      200708061842.37805.sylvain.joyeux@m4x.org under e0a4c0830708060903v3fa71396s88460ded5d0d8721@mail.gmail.com
      46B76A46.1000902@davidflanagan.com under nobody
      fcfe41700708061330m102fb4f5tadc8b96d74eec099@mail.gmail.com under 46B76A46.1000902@davidflanagan.com
      46B83D83.1060401@atdot.net under fcfe41700708061330m102fb4f5tadc8b96d74eec099@mail.gmail.com
      c67184de0708070656h311fa601ndde32bd89872e520@mail.gmail.com under 46B83D83.1060401@atdot.net
      46B87F2A.1070801@cesmail.net under c67184de0708070656h311fa601ndde32bd89872e520@mail.gmail.com
      fcfe41700708070728h5a3ed256sb5b3506af8676b0f@mail.gmail.com under 46B83D83.1060401@atdot.net
      4e4a257e0708070124h273cbf52la918f07525d28c40@mail.gmail.com under nobody
      20070807122718.B4ECCE031F@mail.bc9.jp under 4e4a257e0708070124h273cbf52la918f07525d28c40@mail.gmail.com
      51BF19F7-15F6-4399-956C-008CC1432D0D@grayproductions.net under nobody
      7524A45A1A5B264FA4809E2156496CFBE72D37@ITOMAE2KM01.AD.QINTRA.COM under 51BF19F7-15F6-4399-956C-008CC1432D0D@grayproductions.net
      E1IIpF4-0002jt-HU@x31 under 51BF19F7-15F6-4399-956C-008CC1432D0D@grayproductions.net
      9E793D2A-43A3-4FC9-AFA0-3F90CB3F1C88@grayproductions.net under E1IIpF4-0002jt-HU@x31
      E1IIpwK-0002xH-1H@x31 under 9E793D2A-43A3-4FC9-AFA0-3F90CB3F1C88@grayproductions.net
      Pine.GSO.4.64.0708081840360.23109@brains.eng.cse.dmu.ac.uk under E1IIpF4-0002jt-HU@x31
      A0ADD0FF-6958-4FE5-8486-9A11A9E67C18@grayproductions.net under Pine.GSO.4.64.0708081840360.23109@brains.eng.cse.dmu.ac.uk
      7524A45A1A5B264FA4809E2156496CFBE72D48@ITOMAE2KM01.AD.QINTRA.COM under A0ADD0FF-6958-4FE5-8486-9A11A9E67C18@grayproductions.net
      E1IIpt7-0002wG-Hm@x31 under Pine.GSO.4.64.0708081840360.23109@brains.eng.cse.dmu.ac.uk
      4656BC23.5010201@ruby-lang.org under nobody
      465EBEC8.6020103@dan42.com under 4656BC23.5010201@ruby-lang.org
      20070807205243.GB5550@suse.de under 465EBEC8.6020103@dan42.com
      200707280246.l6S2k9Mi011192@ci.ruby-lang.org under nobody
      200707281324.l6SDOlxW012255@ci.ruby-lang.org under 200707280246.l6S2k9Mi011192@ci.ruby-lang.org
      20070808010035.AD274E02E8@mail.bc9.jp under 200707281324.l6SDOlxW012255@ci.ruby-lang.org
      20070808185938.GA16490@danisch.de under nobody
      58C3206C-1F09-434A-9870-1EDCB2E62E3C@tomlea.co.uk under 20070808185938.GA16490@danisch.de
      20070808220750.GA4535@danisch.de under 58C3206C-1F09-434A-9870-1EDCB2E62E3C@tomlea.co.uk
      46BA6809.2080405@sarion.co.jp under 20070808220750.GA4535@danisch.de
      46BA305A.4030300@davidflanagan.com under nobody
      46BA33C9.6000103@davidflanagan.com under 46BA305A.4030300@davidflanagan.com
      E1IIvXu-0006Nx-9u@x31 under 46BA305A.4030300@davidflanagan.com
      20070809032839.A63A6E0294@mail.bc9.jp under E1IIvXu-0006Nx-9u@x31
      E1IJDPG-0003zI-6F@x31 under 20070809032839.A63A6E0294@mail.bc9.jp
      46BA5403.4010307@davidflanagan.com under nobody
      20070810004607.6B7BDE02E4@mail.bc9.jp under 46BA5403.4010307@davidflanagan.com
      46BBEF5F.9080102@davidflanagan.com under 20070810004607.6B7BDE02E4@mail.bc9.jp
      46BBF475.6040706@davidflanagan.com under 46BBEF5F.9080102@davidflanagan.com
      200708100831.09731.sylvain.joyeux@m4x.org under 46BBF475.6040706@davidflanagan.com
      200708100828.23820.sylvain.joyeux@m4x.org under 20070810004607.6B7BDE02E4@mail.bc9.jp
      46BC70E8.8080002@qwest.com under nobody
      46BC73DA.4040608@qwest.com under 46BC70E8.8080002@qwest.com
      20070810143533.CF222E02AB@mail.bc9.jp under 46BC70E8.8080002@qwest.com
      46BC7928.20700@qwest.com under 20070810143533.CF222E02AB@mail.bc9.jp
      daff01530708122145i2cdaf470t6320c960308562e2@mail.gmail.com under nobody
      46C0F09B.2090908@gmail.com under daff01530708122145i2cdaf470t6320c960308562e2@mail.gmail.com
      daff01530708140603v4aecc039o42d173d2ad3d692a@mail.gmail.com under 46C0F09B.2090908@gmail.com
      46C1CBA4.5000106@ruby-lang.org under daff01530708140603v4aecc039o42d173d2ad3d692a@mail.gmail.com
      7524A45A1A5B264FA4809E2156496CFBE72D67@ITOMAE2KM01.AD.QINTRA.COM under daff01530708140603v4aecc039o42d173d2ad3d692a@mail.gmail.com
      daff01530708160545t7bff57a7rcf989ec768d387@mail.gmail.com under 7524A45A1A5B264FA4809E2156496CFBE72D67@ITOMAE2KM01.AD.QINTRA.COM
      Pine.GSO.4.64.0708161456350.3366@brains.eng.cse.dmu.ac.uk under daff01530708160545t7bff57a7rcf989ec768d387@mail.gmail.com
      daff01530708171857xaec0b41p227e35c429c71cc8@mail.gmail.com under Pine.GSO.4.64.0708161456350.3366@brains.eng.cse.dmu.ac.uk
      46C9B0B4.3020107@qwest.com under daff01530708171857xaec0b41p227e35c429c71cc8@mail.gmail.com
      20070816172338.GA16802@sam-desktop under daff01530708160545t7bff57a7rcf989ec768d387@mail.gmail.com
      20070820113013.CEFF5E0273@mail.bc9.jp under daff01530708160545t7bff57a7rcf989ec768d387@mail.gmail.com
      46C9A4EF.3010506@qwest.com under 20070820113013.CEFF5E0273@mail.bc9.jp
      daff01530708200942x1061aa9em8cc3e1605b2e2f4b@mail.gmail.com under 46C9A4EF.3010506@qwest.com
      46CA2F8B.3010103@gmail.com under daff01530708200942x1061aa9em8cc3e1605b2e2f4b@mail.gmail.com
      24A45A1A5B264FA4809E2156496CFBE72D67@ITOMAE2KM01.AD.QINTRA.COM under daff01530708140603v4aecc039o42d173d2ad3d692a@mail.gmail.com
      86d4xpbzoy.fsf@bitty.lumos.us under daff01530708122145i2cdaf470t6320c960308562e2@mail.gmail.com
      daff01530708141514s72f697e6rdc42974c6a58d968@mail.gmail.com under 86d4xpbzoy.fsf@bitty.lumos.us
      OF304AE38C.CF1C5D08-ONC2257338.001C156E-C2257338.001C2761@stonesoft.com under daff01530708141514s72f697e6rdc42974c6a58d968@mail.gmail.com
      Pine.GSO.4.64.0708151127330.18645@brains.eng.cse.dmu.ac.uk under daff01530708141514s72f697e6rdc42974c6a58d968@mail.gmail.com
      863ayj9yo3.fsf@bitty.lumos.us under daff01530708141514s72f697e6rdc42974c6a58d968@mail.gmail.com
      D1FBC429380C4767A2729538C7BA981D.MAI@maniindiatech.com under daff01530708122145i2cdaf470t6320c960308562e2@mail.gmail.com
      20070820191253.GA9374@uk.tiscali.com under D1FBC429380C4767A2729538C7BA981D.MAI@maniindiatech.com
      46C00B17.5090202@sun.com under nobody
      46C6628B.9010407@sun.com under 46C00B17.5090202@sun.com
      20070814090704.GA32034@uk.tiscali.com under nobody
      20070828090128.GB30146@uk.tiscali.com under 20070814090704.GA32034@uk.tiscali.com
      20070829101113.GA7111@uk.tiscali.com under 20070828090128.GB30146@uk.tiscali.com
      20070814101715.GA9138@bart.bertram-scharpf.homelinux.com under nobody
      20070814102540.GA9586@bart.bertram-scharpf.homelinux.com under 20070814101715.GA9138@bart.bertram-scharpf.homelinux.com
      20070815083838.GA357@bart.bertram-scharpf.homelinux.com under 20070814101715.GA9138@bart.bertram-scharpf.homelinux.com
      20070815093851.GA13445@uk.tiscali.com under 20070815083838.GA357@bart.bertram-scharpf.homelinux.com
      20070816112720.GA7078@bart.bertram-scharpf.homelinux.com under 20070815093851.GA13445@uk.tiscali.com
      20070814214858.GA23413@danisch.de under nobody
      20070815054503.GA31250@uk.tiscali.com under 20070814214858.GA23413@danisch.de
      20070815054821.GA31783@uk.tiscali.com under 20070815054503.GA31250@uk.tiscali.com
      20070817151709.GA14557@danisch.de under 20070815054503.GA31250@uk.tiscali.com
      20070817152702.GA11676@uk.tiscali.com under 20070817151709.GA14557@danisch.de
      372109E149E8084D8E6C7D9CFD82E06329CFF0ACCC@NA-EXMSG-C115.redmond.corp.microsoft.com under 20070817152702.GA11676@uk.tiscali.com
      7d9a1f530708171208o66bd26b0u2ac3249635ad87a3@mail.gmail.com under 372109E149E8084D8E6C7D9CFD82E06329CFF0ACCC@NA-EXMSG-C115.redmond.corp.microsoft.com
      372109E149E8084D8E6C7D9CFD82E06329CFF0ACF8@NA-EXMSG-C115.redmond.corp.microsoft.com under 7d9a1f530708171208o66bd26b0u2ac3249635ad87a3@mail.gmail.com
      Pine.LNX.4.64.0708171839380.19838@rubypal.com under 372109E149E8084D8E6C7D9CFD82E06329CFF0ACF8@NA-EXMSG-C115.redmond.corp.microsoft.com
      7524A45A1A5B264FA4809E2156496CFBE72D7E@ITOMAE2KM01.AD.QINTRA.COM under 7d9a1f530708171208o66bd26b0u2ac3249635ad87a3@mail.gmail.com
      20070817210638.GA28361@uk.tiscali.com under 7d9a1f530708171208o66bd26b0u2ac3249635ad87a3@mail.gmail.com
      7d9a1f530708171210x14a4ebcdnab3602ad1959944e@mail.gmail.com under 372109E149E8084D8E6C7D9CFD82E06329CFF0ACCC@NA-EXMSG-C115.redmond.corp.microsoft.com
      777C6B43-1C08-4DF0-9137-11FAC9628A1E@zenspider.com under 372109E149E8084D8E6C7D9CFD82E06329CFF0ACCC@NA-EXMSG-C115.redmond.corp.microsoft.com
      d8a74af10708141459t7d12ceabla8b0f9ac875fe81f@mail.gmail.com under nobody
      Pine.GSO.4.64.0708151044510.18645@brains.eng.cse.dmu.ac.uk under d8a74af10708141459t7d12ceabla8b0f9ac875fe81f@mail.gmail.com
      7d9a1f530708150433i6dc028cgd7b5878233938dc9@mail.gmail.com under Pine.GSO.4.64.0708151044510.18645@brains.eng.cse.dmu.ac.uk
      fcfe41700708150630m6640fba9uce61530d78fe1d07@mail.gmail.com under 7d9a1f530708150433i6dc028cgd7b5878233938dc9@mail.gmail.com
      d8a74af10708152204l344de57fqf00ff2e880c0de04@mail.gmail.com under fcfe41700708150630m6640fba9uce61530d78fe1d07@mail.gmail.com
      46C51F13.2070104@cesmail.net under nobody
      335e48a90708180348w5304e0fcp98dd9aad304055b6@mail.gmail.com under nobody
      E1IMPqc-00063a-FS@x31 under 335e48a90708180348w5304e0fcp98dd9aad304055b6@mail.gmail.com
      46C70D57.8020604@ruby-lang.org under E1IMPqc-00063a-FS@x31
      335e48a90708181013g2ccc7007rfd9e3e66ecc80d63@mail.gmail.com under E1IMPqc-00063a-FS@x31
      1187473597.290930.199140@w3g2000hsg.googlegroups.com under 335e48a90708180348w5304e0fcp98dd9aad304055b6@mail.gmail.com
      F58FE69873E2D5459B72C347DE15824116B61980CB@NA-EXMSG-C112.redmond.corp.microsoft.com under nobody
      46CAFA7B.9060904@atdot.net under nobody
      d8a74af10708210846s6ccd7649u16ca78cdb308f68f@mail.gmail.com under nobody
      43d756720708211139m17639cb7hb2162ca5fcf3d727@mail.gmail.com under d8a74af10708210846s6ccd7649u16ca78cdb308f68f@mail.gmail.com
      d4e4955b0708221252g563499f5oec9e6dc0321f099c@mail.gmail.com under d8a74af10708210846s6ccd7649u16ca78cdb308f68f@mail.gmail.com
      Pine.GSO.4.64.0708231005450.22635@brains.eng.cse.dmu.ac.uk under d4e4955b0708221252g563499f5oec9e6dc0321f099c@mail.gmail.com
      46D5215A.2020705@sun.com under Pine.GSO.4.64.0708231005450.22635@brains.eng.cse.dmu.ac.uk
      46D57CC2.5010409@cesmail.net under 46D5215A.2020705@sun.com
      46D57E8A.1020804@sun.com under 46D57CC2.5010409@cesmail.net
      Pine.GSO.4.64.0708291559430.22900@brains.eng.cse.dmu.ac.uk under 46D57E8A.1020804@sun.com
      d8a74af10708291646y422ac6b5u985124384e70ec5d@mail.gmail.com under Pine.GSO.4.64.0708291559430.22900@brains.eng.cse.dmu.ac.uk
      46D580B6.9050507@sun.com under 46D5215A.2020705@sun.com
      9F100E54-DAC6-41DF-9876-423B614BCD64@segment7.net under 46D5215A.2020705@sun.com
      20070822005417.GA53919@lizzy.catnook.local under nobody
      46CBE1C2.7070109@davidflanagan.com under nobody
      46CC202B.7000206@gmail.com under 46CBE1C2.7070109@davidflanagan.com
      3a94cf510708220450o38400ae7hd71b7334f5fde380@mail.gmail.com under 46CC202B.7000206@gmail.com
      1aedab802e2a57becaf23d5d59163ab2@localhost under 3a94cf510708220450o38400ae7hd71b7334f5fde380@mail.gmail.com
      3a94cf510708220856r6804223ob1dfc823290baf03@mail.gmail.com under 1aedab802e2a57becaf23d5d59163ab2@localhost
      34435dbb849386ca654098bbd7cfdffd@localhost under 3a94cf510708220856r6804223ob1dfc823290baf03@mail.gmail.com
      20070823052055.GA434@ensemble.local under 34435dbb849386ca654098bbd7cfdffd@localhost
      00000000@generated-message-id.listlibrary.net under 20070823052055.GA434@ensemble.local
      40700@swip002.ftl.affinity.com under 20070823052055.GA434@ensemble.local
      3a94cf510708230447i4d71d8e9t8a7c7cbdcf99832f@mail.gmail.com under 40700@swip002.ftl.affinity.com
      20070823143356.GA14979@uk.tiscali.com under 20070823052055.GA434@ensemble.local
      46CC6E75.9000503@davidflanagan.com under 3a94cf510708220856r6804223ob1dfc823290baf03@mail.gmail.com
      46CC8CFB.6070404@davidflanagan.com under 46CC6E75.9000503@davidflanagan.com
      3a94cf510708221551o36d68629odc1055a666ad1c3a@mail.gmail.com under 46CC8CFB.6070404@davidflanagan.com
      Pine.LNX.4.64.0708252138470.6916@rubypal.com under 46CC8CFB.6070404@davidflanagan.com
      46D0EF54.3000702@atdot.net under Pine.LNX.4.64.0708252138470.6916@rubypal.com
      Pine.LNX.4.64.0708260729370.10263@rubypal.com under 46D0EF54.3000702@atdot.net
      E1INrTy-0002l5-R9@x31 under 46CBE1C2.7070109@davidflanagan.com
      46CC7C71.4030102@davidflanagan.com under E1INrTy-0002l5-R9@x31
      46CC7638.6070801@davidflanagan.com under E1INrTy-0002l5-R9@x31
      46D2EB1A.6080207@sun.com under E1INrTy-0002l5-R9@x31
      46D2FC02.6090904@atdot.net under 46D2EB1A.6080207@sun.com
      46D308BD.9040506@sun.com under 46D2FC02.6090904@atdot.net
      46CC5605.9050003@maven-group.org under nobody
      Pine.LNX.4.64.0708221203440.20423@rubypal.com under 46CC5605.9050003@maven-group.org
      200708221810.08719.haisenko@comdasys.com under 46CC5605.9050003@maven-group.org
      46CC8548.3010802@davidflanagan.com under nobody
      46CC8915.2050406@atdot.net under 46CC8548.3010802@davidflanagan.com
      46CC95D8.7010106@davidflanagan.com under 46CC8915.2050406@atdot.net
      397147715c8576a4092df8a5630394b2@localhost under 46CC95D8.7010106@davidflanagan.com
      050d05ef64c4a71c796eb975f89b640d@localhost under 397147715c8576a4092df8a5630394b2@localhost
      7524A45A1A5B264FA4809E2156496CFBE72D94@ITOMAE2KM01.AD.QINTRA.COM under 397147715c8576a4092df8a5630394b2@localhost
      46CCE027.30307@dan42.com under nobody
      e3caf1460706051414x41ad8f69k7068d26a835fd232@mail.gmail.com under nobody
      4665D7F6.9050705@davidflanagan.com under e3caf1460706051414x41ad8f69k7068d26a835fd232@mail.gmail.com
      e3caf1460708230639p5f699143s8d3f178d743c8378@mail.gmail.com under 4665D7F6.9050705@davidflanagan.com
      F58FE69873E2D5459B72C347DE15824116B6199049@NA-EXMSG-C112.redmond.corp.microsoft.com under nobody
      46CE0A81.1050205@qwest.com under nobody
      46CE1055.6010908@atdot.net under 46CE0A81.1050205@qwest.com
      DD15BA02-3A4B-474B-AD32-9C6B9EC4D302@fallingsnow.net under 46CE1055.6010908@atdot.net
      4088e1c90708232328v4e2cd446xe6016b1f740a92a1@mail.gmail.com under nobody
      20070824082136.EC5E2E0357@mail.bc9.jp under 4088e1c90708232328v4e2cd446xe6016b1f740a92a1@mail.gmail.com
      4088e1c90708241030i28c74786v1b50df67402ca53e@mail.gmail.com under 20070824082136.EC5E2E0357@mail.bc9.jp
      46D0605B.8000008@gmx.de under 4088e1c90708232328v4e2cd446xe6016b1f740a92a1@mail.gmail.com
      f93a6bcc0708251008y4fa7d3c4qc3fbac157de1e2b0@mail.gmail.com under 46D0605B.8000008@gmx.de
      46CF2040.2050504@davidflanagan.com under nobody
      46CF2A6F.4040308@qwest.com under 46CF2040.2050504@davidflanagan.com
      Pine.LNX.4.64.0708241628140.5847@rubypal.com under 46CF2A6F.4040308@qwest.com
      E1IOjq4-0007Dl-Tg@x31 under 46CF2A6F.4040308@qwest.com
      7d9a1f530708250122k43cdd24fo6f0cdc8efe972abb@mail.gmail.com under nobody
      E1IOrPN-00072z-7U@x31 under 7d9a1f530708250122k43cdd24fo6f0cdc8efe972abb@mail.gmail.com
      op.txl0z2w7ye1j0n@dragon.local under E1IOrPN-00072z-7U@x31
      E1IOtw1-00041K-Ns@x31 under op.txl0z2w7ye1j0n@dragon.local
      9e7db9110708250850u2ea6627eu5aa7cdb2823fe22a@mail.gmail.com under E1IOtw1-00041K-Ns@x31
      E1IOyK2-0005j0-P1@x31 under 9e7db9110708250850u2ea6627eu5aa7cdb2823fe22a@mail.gmail.com
      9e7db9110708251214x6d0afdb9k5d8a2f129e16d5fb@mail.gmail.com under E1IOyK2-0005j0-P1@x31
      E1IPUiD-0002im-0b@x31 under 9e7db9110708251214x6d0afdb9k5d8a2f129e16d5fb@mail.gmail.com
      op.txprt7o0ye1j0n@dragon.local under E1IPUiD-0002im-0b@x31
      dbfc82860708270427h2607e1d9mae134deaa272e384@mail.gmail.com under op.txprt7o0ye1j0n@dragon.local
      E1IPeMu-0005tE-Tb@x31 under op.txprt7o0ye1j0n@dragon.local
      op.txq82qgbye1j0n@dragon.local under E1IPeMu-0005tE-Tb@x31
      dbfc82860708262339g5c437facy97a251fd79f1d31e@mail.gmail.com under E1IOrPN-00072z-7U@x31
      E1IPZHT-0004h5-4n@x31 under dbfc82860708262339g5c437facy97a251fd79f1d31e@mail.gmail.com
      46CFEFE2.5040809@atdot.net under 7d9a1f530708250122k43cdd24fo6f0cdc8efe972abb@mail.gmail.com
      16956643-A0EE-47E7-BB4D-9FCCC5796FD0@segment7.net under nobody
      922F7BA7-89B7-427A-9FD6-35833B5D87A7@segment7.net under 16956643-A0EE-47E7-BB4D-9FCCC5796FD0@segment7.net
      20060718213611.65816A97001C@rubyforge.org under nobody
      200607190725.k6J7PbjG001005@sharui.kanuma.tochigi.jp under 20060718213611.65816A97001C@rubyforge.org
      A8C8CD92-1D4C-492C-919C-DE01CE8FCCE0@dcs.gla.ac.uk under 200607190725.k6J7PbjG001005@sharui.kanuma.tochigi.jp
      200607260113.k6Q1Dc82015077@sharui.kanuma.tochigi.jp under A8C8CD92-1D4C-492C-919C-DE01CE8FCCE0@dcs.gla.ac.uk
      46D26D20.2000405@ruby-lang.org under 200607260113.k6Q1Dc82015077@sharui.kanuma.tochigi.jp
      E1IPYqH-0004Wr-38@x31 under 46D26D20.2000405@ruby-lang.org
      20070827222111.GA21576@bart.bertram-scharpf.homelinux.com under nobody
      20070829062434.46167E0331@mail.bc9.jp under 20070827222111.GA21576@bart.bertram-scharpf.homelinux.com
      46D52720.4080305@gmail.com under 20070829062434.46167E0331@mail.bc9.jp
      20070830083726.GA22896@bart.bertram-scharpf.homelinux.com under 20070829062434.46167E0331@mail.bc9.jp
      20070829164912.M60248@jena-stew.de under nobody
      200708300215.FMLAAB29468.ruby-core@ruby-lang.org under 20070829164912.M60248@jena-stew.de
      20070829172012.M38417@jena-stew.de under 200708300215.FMLAAB29468.ruby-core@ruby-lang.org
      AC97B6AA-23BA-44BF-AC1C-4897931F20FE@misnomer.us under 20070829172012.M38417@jena-stew.de
      20070830112736.M5238@jena-stew.de under AC97B6AA-23BA-44BF-AC1C-4897931F20FE@misnomer.us
      46D6B282.8010206@dymaxion.ca under 20070829172012.M38417@jena-stew.de
      20070830173658.M91064@jena-stew.de under 46D6B282.8010206@dymaxion.ca
      46D5D510.7060706@qwest.com under nobody
      20070830020431.5E1E7E0339@mail.bc9.jp under 46D5D510.7060706@qwest.com
      46D629A4.9000808@gmail.com under 20070830020431.5E1E7E0339@mail.bc9.jp
      20070830123014.GA25287@uk.tiscali.com under nobody
      7524A45A1A5B264FA4809E2156496CFBE72DBD@ITOMAE2KM01.AD.QINTRA.COM under nobody
      Pine.GSO.4.64.0708301844080.337@brains.eng.cse.dmu.ac.uk under nobody
      20070830191148.GA8233@bart.bertram-scharpf.homelinux.com under nobody
      46D7B697.1070201@davidflanagan.com under nobody
      E1IR0EE-0001aH-A5@x31 under 46D7B697.1070201@davidflanagan.com
      6.0.0.20.2.20070831193144.093fbe30@localhost under 46D7B697.1070201@davidflanagan.com
      939442FF-EDF6-41C5-BC76-189656C64FE9@mac.com under 46D7B697.1070201@davidflanagan.com
      46D8473F.1000406@sun.com under 46D7B697.1070201@davidflanagan.com
      9e7db9110708311100l57fcf078tec9f5e3a65df7a02@mail.gmail.com under 46D8473F.1000406@sun.com
      46D7BABE.60101@davidflanagan.com under nobody
      E1IR15x-0001r7-G0@x31 under 46D7BABE.60101@davidflanagan.com
      200708311019.27556.haisenko@comdasys.com under E1IR15x-0001r7-G0@x31
      EB584206-09BB-43B9-986F-12F1DE73F20A@grayproductions.net under 200708311019.27556.haisenko@comdasys.com
      46D7D1FF.2030004@advancedsl.com.ar under E1IR15x-0001r7-G0@x31
      6.0.0.20.2.20070831200953.07c23b00@localhost under 46D7D1FF.2030004@advancedsl.com.ar
      46D8167B.8030808@nibor.org under 6.0.0.20.2.20070831200953.07c23b00@localhost
      9e7db9110708310924u1358ff2ahd5cb82fc3e4e678@mail.gmail.com under 46D8167B.8030808@nibor.org
      dbfc82860708310155y207074c5w7e37acf25d300a94@mail.gmail.com under E1IR15x-0001r7-G0@x31
      E1IR30w-0002Ux-6r@x31 under dbfc82860708310155y207074c5w7e37acf25d300a94@mail.gmail.com
      3B63D4BC-EF35-48E8-91BB-67181D79270D@grayproductions.net under E1IR30w-0002Ux-6r@x31
      Pine.GSO.4.64.0708311415320.337@brains.eng.cse.dmu.ac.uk under 3B63D4BC-EF35-48E8-91BB-67181D79270D@grayproductions.net
      46D84BEC.3000909@davidflanagan.com under E1IR15x-0001r7-G0@x31
      46D84E74.7050906@davidflanagan.com under E1IR15x-0001r7-G0@x31
      46D84D65.2020604@sun.com under nobody".split(/\n\s+/)

    found_parents = []
    @ts.each do |thread|
      thread.each do |message|
        found_parents << "#{message.message_id} under " + (message.root? ? "nobody" : message.parent.message_id)
      end
    end
    # check for extra messages
    assert_equal [], found_parents - expected_parents
    # check for missing messages
    assert_equal [], expected_parents - found_parents
    # check order
    assert_equal expected_parents, found_parents
  end

  def test_threading_by_quotes
    [
      initial_message = Message.new(threaded_message(:initial_message), 'test', '00000000'),
      regular_reply   = Message.new(threaded_message(:regular_reply), 'test', '00000000'),
      quoting_reply   = Message.new(threaded_message(:quoting_reply), 'test', '00000000'),
    ].each { |m| @ts << m }
    @ts.send(:finish) # force the final threading
    assert_equal regular_reply.message_id, @ts.containers[quoting_reply.message_id].parent.message_id
  end

  def test_retrieve_split_threads_from
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    ts = ThreadSet.new 'slug', '2007', '12'
    ts << Message.new(threaded_message(:child), 'test', '000child')
    nil.expects(:delete)
    ts.expects(:store)
    @ts.expects(:store)
    @ts.send(:retrieve_split_threads_from, ts)
    assert ts.containers.empty?
    assert_equal 1, @ts.length
    assert_equal 2, @ts.containers['root@example.com'].count
  end

  def test_retrieve_split_threads_from_not_non_replies
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    ts = ThreadSet.new 'slug', '2007', '12'
    # This message will be recognized as a split thread, but a parent for it
    # doesn't exist in @ts
    ts << Message.new(threaded_message(:regular_reply), 'test', '000child')
    ts.expects(:store)
    @ts.expects(:store)
    @ts.send(:retrieve_split_threads_from, ts)
    assert_equal 1, @ts.length
    assert_equal 1, ts.length
  end

  def test_message_count
    # was failing to load Message-ID: <BAYC1-PASMTP14295C87CFA7B12CC8A613B4770@CEZ.ICE>
    ts = ThreadSet.new 'example', '2007', '12'
    rejoin_splits("2007-12").each do |mail|
      m = Message.new(mail, 'example', '00000000')
      ts << m
    end
    assert_equal %w{1196188048.22546.1223520349@webmail.messagingengine.com 4742D87E.7020701@casual-tempest.net}, ts.send(:root_set).collect(&:message_id)
    assert_equal 4, ts.message_count(false)
    # arguably, this could be 9, but dropping the empty container
    # 4742D87E.7020701@casual-tempest.net makes as more sense than keeping it,
    # which is what differentiates between merging 'both dummies' and reparenting
    assert_equal 8, ts.message_count(true)
  end

  def test_rejoin_splits
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

  def test_rejoin_splits_on_subject
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

  def test_redirect_single
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    thread = @ts.containers['root@example.com']
    $archive.expects(:delete).with(thread.key)
    @ts.send(:redirect, thread, '2009', '02')
    assert @ts.containers.empty?
  end

  def test_redirect_thread
    @ts << Message.new(threaded_message(:root), 'test', '0000root')
    @ts << Message.new(threaded_message(:child), 'test', '0000root')
    thread = @ts.containers['root@example.com']
    $archive.expects(:delete)
    @ts.send(:redirect, thread, '2009', '02')
    assert @ts.containers.empty?
  end

  def test_plus_month
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

#  def test_caching
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
