require_relative 'container_storage'
require_relative 'summary_storage'

class SummaryContainerStorage
  include ContainerStorage

  def serialize_value
    SummaryStorage.new(container.value).serialize
  end

  def self.deserialize_value h
    SummaryStorage.deserialize h
  end

  def self.container_class
    MessageContainer
  end
end

