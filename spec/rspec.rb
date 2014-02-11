require 'rspec'
require 'ostruct'
require_relative '../model/storage/riak_storage'
require_relative '../model/storage/redis_storage'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.alias_example_to :expect_it

  config.before(:each) do
    module RiakStorage::ClassMethods
      def db_client
        FakeStorage.new
      end
    end

    module RedisStorage
      def db_client
        FakeStorage.new
      end
    end
  end
end

# http://stackoverflow.com/questions/12260534/using-implicit-subject-with-expect-in-rspec-2-11
RSpec::Core::MemoizedHelpers.module_eval do
  alias to should
  alias to_not should_not
end

class FakeStorage
  def method_missing *args
    raise RuntimeError, "accidentally called a real storage method in test"
  end
end

class FakeMessage
  attr_reader :message_id, :message, :key

  def initialize message_id='id@example.com'
    @message_id = message_id
  end

  def list ; OpenStruct.new(slug: 'slug') ; end
  def from ; 'from@example.com' ; end
  def subject_is_reply? ; false ; end
  def date ; Time.new(2013, 11, 21) ; end
  def email ; 'email' ; end
end

class FakeStorableMessage < FakeMessage
  def email ; OpenStruct.new(canonicalized_from_email: 'from@example.com') ; end
  def source ; 'source' ; end
  def call_number ; 'callnumber' ; end
end

FakeThreadSet = Struct.new(:root_set) do
  def slug ; 'slug' ; end
  def date ; Time.new(2014, 12) ; end
end
FakeThreadLink = Struct.new(:call_number, :n_subject)
def fake_thread_set call_numbers
  FakeThreadSet.new call_numbers.map { |c| FakeThreadLink.new(c, "subject #{c}") }
end

