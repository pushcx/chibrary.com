require_relative 'container_repo'
require_relative 'summary_repo'

class SummaryContainerRepo
  include ContainerRepo

  def serialize_value
    SummaryRepo.new(container.value).serialize
  end

  def self.deserialize_value h
    SummaryRepo.deserialize h
  end

  def self.container_class
    MessageContainer
  end
end
