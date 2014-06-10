class Thread
  include Enumerable

  attr_reader :containers

  def initialize
  end

  def each &block
    containers.each &block
  end

  def hydrate message
    raise TODO
  end

  def root_call_number
    # call number of root
    raise TODO
  end

  def call_numbers
    map(&:call_number).compact.sort
  end

  def message_ids
    map(&:message_id).uniq.compact.sort
  end

  def n_subjects
    map(&:n_subject).uniq.compact.sort
  end

  def self.from_containers
    raise TODO
  end

  def self.from_summaries
    raise TODO
  end
end
