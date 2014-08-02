require 'forwardable'

require 'container'

module Chibrary

class Thread
  include Enumerable

  attr_reader container_tree

  extend Forwardable
  def_delegators :@container_tree, :<=>, :each

  def initialize container_tree
    @container_tree = container_tree
  end

  def summarize
    @container_tree = container_tree.summarize
  end

  def messagize messages
    @container_tree = container_tree.messagize messages
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
end

end # Chibrary
