require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class FakeStorage
  def bucket *args
    raise "accidentally called a real storage method in test"
  end
end

