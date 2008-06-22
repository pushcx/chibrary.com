require 'rubygems'
require 'test/unit'
require 'haml'
require 'mocha'
require 'pp'
require 'redgreen'
require 'yaml'

# path magic from p152 of Programming Ruby
$:.unshift File.join(File.dirname(__FILE__), "..", "bin")
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'storage'
$archive = $cachedhash = nil # avoid accidental real changes

# Don't ever actually make pop connections
require 'net/pop'
class Net::POP3
  def initialize server, port ; raise "un-mocked POP3 call" ; end
end

# Don't really log dev stuff
require 'log'
class Log
  def initialize worker ; @worker = worker ; end
  def log status, message ; message ; end
end

class Test::Unit::TestCase
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

