require_relative 'container_repo'
require_relative 'message_repo'

class MessageContainerRepo
  include ContainerRepo

  def serialize_value
    MessageRepo.new(container.value).serialize
  end

  def self.deserialize_value h
    MessageRepo.deserialize h
  end

  def self.container_class
    MessageContainer
  end
end
