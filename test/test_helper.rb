require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class FakeStore
  def method_missing
    fail "accidentally called a real storage method in test"
  end
end
$riak = $archive = $cachedhash = FakeStore.new # avoid accidental real changes

require 'net/pop'
class Net::POP3
  def initialize server, port ; raise "un-mocked POP3 call" ; end
end

require 'log'
class Log
  def in_test_mode? ; true ; end
  def log status, message ; message ; end
end

class ActiveSupport::TestCase
  @@fixtures = {}
  def self.fixtures list
    [list].flatten.each do |fixture|
      self.class_eval do
        define_method(fixture) do |item|
          filename = File.join(File.dirname(__FILE__), 'fixture', "#{fixture.to_s}.yaml")
          @@fixtures[fixture] ||= YAML::load_file(filename)
          @@fixtures[fixture][item.to_s]
        end
      end
    end
  end
end

class ThreadingTest < ActiveSupport::TestCase
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

def mock_list
  # mock list object
  list = mock 'mock_list'
  list.expects('slug').at_least(0).returns('slug')
  list.expects(:[]).with('name').at_least(0).returns('Example List')
  list.expects(:[]).with('homepage').at_least(0).returns(nil)
  list.expects(:[]).with('description').at_least(0).returns(nil)
  $archive.expects(:has_key?).with("list/slug").at_least(0).returns(true)
  List.expects(:new).at_least(1).returns(list)
  list
end
