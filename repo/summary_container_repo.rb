require_relative 'summary_repo'
require_relative '../value/message_id'
require_relative '../entity/container'

module Chibrary

class SummaryContainerRepo
  attr_reader :container

  def initialize container
    @container = container
  end

  def serialize c=container
    {
      key:      c.key.to_s,
      value:    SummaryRepo.new(c.value).serialize,
      children: c.children.map { |child| serialize(child) },
    }
  end

  def self.deserialize h
    h.deep_symbolize_keys!
    container = Container.new MessageId.new(h.fetch(:key)), SummaryRepo.deserialize(h.fetch(:value))
    h[:children].each do |child_hash|
      container.adopt deserialize(child_hash)
    end
    container
  end
end

end # Chibrary
