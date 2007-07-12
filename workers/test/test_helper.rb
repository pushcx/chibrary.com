require 'rubygems'
require 'redgreen'
require 'yaml'
require 'pp'
require 'ostruct'

# path magic from p152 of Programming Ruby
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Don't make a real AWS S3 connection
AWS_connection = true
require 'aws'

# Mock the S3Object so tests run offline
require 'message'
require 'test/mock'

class Message 
  alias old_initialize initialize
  def initialize *args
    old_initialize *args
    @S3Object = Mock.new
  end
end

class Test::Unit::TestCase
  @@fixtures = {}
  def self.fixtures list
    [list].flatten.each do |fixture|
      self.class_eval do
        define_method(fixture) do |item|
          @@fixtures[fixture] ||= YAML::load_file("test/fixtures/#{fixture.to_s}.yaml")
          @@fixtures[fixture][item.to_s]
        end
      end
    end
  end
end
