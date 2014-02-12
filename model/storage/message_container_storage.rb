require_relative 'container_storage'
require_relative 'message_storage'

class MessageContainerStorage
  include ContainerStorage

  def serialize_value
    MessageStorage.new(container.value).serialize
  end

  def self.deserialize_value h
    MessageStorage.deserialize h
  end

  def self.container_class
    MessageContainer
  end
end
