require 'rspec'
require 'ostruct'
require_relative '../model/storage/riak_storage'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    module RiakStorage::ClassMethods
      def db_client
        FakeStorage.new
      end
    end
  end
end

class FakeStorage
  def bucket *args
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
