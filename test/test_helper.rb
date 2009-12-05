ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all
end

$archive = $cachedhash = nil # avoid accidental real changes

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
          filename = File.join(File.dirname(__FILE__), 'fixtures', "#{fixture.to_s}.yaml")
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
