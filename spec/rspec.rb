require 'rspec'
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

