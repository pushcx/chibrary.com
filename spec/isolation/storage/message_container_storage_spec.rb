require_relative '../../rspec'
require_relative '../../../model/storage/message_storage'
require_relative '../../../model/storage/message_container_storage'

describe MessageContainerStorage do
  describe '#serialize_value' do
    FakeMessageContainer = Struct.new(:key, :value)

    it 'delegates to MessageStorage' do
      message = 'message placeholder'
      c = FakeMessageContainer.new 'key', message
      MessageStorage.should_receive(:new).with(message).and_return(double('MessageStorage', serialize: {}))
      MessageContainerStorage.new(c).serialize_value
    end
  end

  describe '::deserialize_value' do
    it 'delegates to MessageStorage' do
      hash = {}
      MessageStorage.should_receive(:deserialize).with(hash)
      MessageContainerStorage.deserialize_value(hash)
    end
  end
end
