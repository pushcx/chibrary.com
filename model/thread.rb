require 'forwardable'

require_relative '../lib/container'
require_relative 'message_container'

module Chibrary

class Thread
  # Main algorithm based on http://www.jwz.org/doc/threading.html

  include Enumerable
  extend Forwardable
  def_delegators :@root, :each, :date, :<=>, :summarize!, :messagize!, :n_subject

  attr_reader :slug, :containers, :root

  def initialize slug, messages
    raise ArgumentError, 'You wanted ::Thread.new, but called Chibrary::Thread.new' if block_given?
    @slug = Slug.new(slug)
    @containers = {} # CallNumber => Container
    messages.each { |m| self << m }
    raise ArgumentError, "Threads require one container so they always have a root" if @containers.empty?
    set_root
  end

  def sym
    Sym.new(slug, date.year, date.month)
  end

  def call_numbers
    map(&:call_number).uniq.sort
  end

  def message_count
    call_numbers.count
  end

  def message_ids
    map(&:message_id).uniq.sort
  end

  def n_subjects
    containers.values.map(&:n_subject).uniq.sort
  end

  def conversation_for? message
    # TODO return false unless slug == message.sym.slug
    return true if message_ids.include? message.message_id
    return false unless n_subjects.include? message.n_subject
    return containers.values.any? { |c| c.message.lines_matching(message.direct_quotes) > 0 }
  end

  def << message_or_container
    message = Container.unwrap message_or_container
    container = store_in_container message
    parent_references container
    set_root
    parent_messages_without_references
  end

  private

  def store_in_container message
    container = find_or_create_container message.message_id
    container.message ||= message
    container
  end

  def find_or_create_container mid
    container = containers.fetch(mid) { MessageContainer.new(mid) }
    containers[mid] ||= container
    container
  end

  def parent_references container, parent=nil
    parent ||= root
    # references are sorted oldest -> youngest
    # walk this container's references and parent them
    container.references.each do |message_id|
      child = find_or_create_container message_id
      parent.adopt child if parent
      parent = child
    end
    # The last reference is trusted to be the parent of this message,
    # but once we have all the messages we confirm.
    parent.adopt container if parent
  end

  def set_root
    @root = nil
    @containers.each do |message_id, container|
      # This is more likely the thread root if...
      # 1. There is no existing root
      # 2. The existing root isn't empty and this one is
      # 3. The existing root has more re/fwd gunk on it
      @root = container if !@root or (!@root.empty? and container.empty?) or container.subject_shorter_than? @root
    end
    @root.orphan
  end

  def parent_messages_without_references
    containers.each do |message_id, container|
      # Can't use container.root? in this test because the tree may be in an
      # inconsistent state after a call to set_root
      next if container.empty? or root == container or !container.message.references.empty?

      chosen_parent = container.parent
      direct_quotes = container.message.direct_quotes

      # Loop through all containers to find the message with the most
      # matched quotes. (Can't just look through the existing containers'
      # children, as this may be a reply to a reply that's also missing
      # its references but hasn't been sorted in yet.)
      best = 0
      @containers.each do |message_id, potential_parent|
        next if potential_parent.empty?
        next if message_id == container.message_id or potential_parent.child_of? container
        count = potential_parent.message.lines_matching direct_quotes
        if count > best
          chosen_parent = potential_parent
          break if count == direct_quotes.size
        end
      end
      chosen_parent ||= root
      container.orphan
      chosen_parent.adopt container
    end
  end

end

end # Chibrary
