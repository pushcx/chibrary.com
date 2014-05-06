require_relative '../rspec'
require_relative '../../repo/message_repo'
require_relative '../../repo/message_container_repo'

describe MessageContainerRepo do
  describe '#serialize_value' do
    FakeMessageContainer = Struct.new(:key, :value)

    it 'delegates to MessageRepo' do
      message = 'message placeholder'
      c = FakeMessageContainer.new 'key', message
      MessageRepo.should_receive(:new).with(message).and_return(double('MessageRepo', serialize: {}))
      MessageContainerRepo.new(c).serialize_value
    end
  end

  describe '::deserialize_value' do
    it 'delegates to MessageRepo' do
      hash = {}
      MessageRepo.should_receive(:deserialize).with(hash)
      MessageContainerRepo.deserialize_value(hash)
    end
  end
end
