require_relative 'summary_repo'
require_relative '../model/summary_container'

module Chibrary

class SummaryContainerRepo
  attr_reader :container

  def initialize container
    @container = container
  end

  def serialize c=container
    {
      key:      c.key,
      value:    SummaryRepo.new(c.value).serialize,
      children: c.children.map { |child| serialize(child) },
    }
  end

  def self.deserialize h
    h.symbolize_keys!
    container = SummaryContainer.new h[:key], SummaryRepo.deserialize(h[:value])
    h[:children].each do |child_hash|
      container.adopt deserialize(child_hash)
    end
    container
  end
end

end # Chibrary
