require_relative 'container_storage'
require_relative 'message_storage'

class MessageContainerStorage
  include ContainerStorage

  def value_to_hash
    MessageStorage.new(container.value).to_hash
  end

  def self.value_from_hash h
    MessageStorage.from_hash h
  end

  def self.container_class
    MessageContainer
  end
end
