require_relative 'container_storage'
require_relative 'summary_storage'

class SummaryContainerStorage
  include ContainerStorage

  def value_to_hash
    SummaryStorage.new(container.value).to_hash
  end

  def self.value_from_hash h
    SummaryStorage.from_hash h
  end

  def self.container_class
    MessageContainer
  end
end

