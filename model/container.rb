require_relative '../value/message_id'
require_relative '../value/summary'
require_relative '../model/message'

module Chibrary

class ContainerNotEmpty < RuntimeError ; end
class KeyNotMessageId < ArgumentError ; end
class KeyMismatch < ArgumentError ; end
class CantWrap < ArgumentError ; end

# Maybe monad + Composite Pattern:
# Each container holds 0 or 1 values and any number of child containers.
# The value is optional so that I can build thread trees even before seeing
# all messages (based on References and In-Reply-To).
class Container
  include Enumerable

  # Generic container key/value/tree code ----------------------------

  attr_reader :key, :value, :parent, :children

  def initialize key, value=nil
    @key = MessageId.new(key)
    raise KeyNotMessageId, @key.to_s unless @key.valid?
    @value = value
    @parent = nil
    @children = []
  end

  def == container
    container.is_a? Container and key == container.key
  end

  def count
    # count of containers with contents, not just containers
    collect { |c| c.empty? ? 0 : 1 }.inject(&:+)
  end

  def depth
    if root?
      0
    else
      parent.depth + 1
    end
  end

  def empty?
    value.nil?
  end

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<Container(#{key}): #{v}>"
  end

  def child_of? c
    return (c == self or (parent and parent.child_of? c))
  end

  def root?
    parent.nil?
  end
  # Different context, same effects
  alias :orphan? :root?

  def root
    if root?
      self
    else
      parent.root
    end
  end

  def each#(&block)
    # yield this container
    yield self
    children.sort!
    # TODO: simpler?
    #@children.each(&block)
    children.each do |child|
      # and yield what all children containers yield
      child.each { |y| yield y }
    end
  end

  # A thread may have empty containers at its root as containers are created
  # from References. The effective root is the first container with a message
  # or with multiple children (meaning we've seen it referenced from multiple
  # messages).
  def effective_root
    if empty? and children.size == 1
      children.first.effective_root
    else
      self
    end
  end

  # When asked for subject or date, return the earliest available.
  def effective_field field
    each do |container|
      return container.value.send(field) unless container.empty?
    end
    nil
  end

  def empty_tree?
    # a thread of dummy containers is not worth saving
    each { |container| return false unless container.empty? }
    return true
  end

  # Break the parent -> child relationship pointing to this container.
  def orphan
    parent.disown self if parent
    @parent = nil
  end

  # Call #orphan on the child and it will call this. If you call this instead
  # of #orphan, the child will have a lingering bad pointer to this container
  # as a parent.
  def disown container
    children.delete container
  end
  protected :disown

  def parent= container
    @parent = container
  end
  protected :parent=

  def adopt container
    return if container.child_of?(self) or self.child_of?(container)

    container.orphan
    children << container
    container.parent = self
  end

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<Container(#{key}): #{v}>"
  end

  # Message/Summary-specific code below this line --------------------

  alias :message    :value
  alias :message_id :key

  def value= value
    raise "Container in a container?" if value.is_a? Container
    raise KeyMismatch, "Message id #{value.message_id} doesn't match container #{key}" if value.respond_to?(:message_id) and value.message_id != key
    raise ContainerNotEmpty, "Can't reassign value #{value} of non-empty container #{key}" unless empty?
    @value = value
  end
  alias :message=   :value=

  def slug        ; effective_field(:slug) ; end
  def call_number ; effective_field(:call_number) or '' ; end
  def date        ; effective_field(:date) or Time.now ; end
  def subject     ; effective_field(:subject) or '' ; end
  def n_subject   ; effective_field(:n_subject) or '' ; end
  def blurb       ; effective_field(:blurb) or '' ; end
  def references  ; effective_field(:references) or [] ; end

  
  def <=> other
    value.respond_to?(:date) ? date <=> other.date : key <=> other.key
  end

  def likely_split_thread?
    message and message.likely_split_thread?
  end

  def less_gunk_than? container
    return subject.gunk_length < container.subject.gunk_length
  end

  def summarize
    return self if value.is_a? Summary

    if value.no_archive?
      c = Container.new key
    else
      c = Container.new key, Summary.from(message)
    end
    children.each { |child| c.adopt(child.summarize) }
    c
  end

  def messagize messages
    return self if value.is_a? Message

    c = Container.new key, messages[call_number]
    children.each { |child| c.adopt(child.messagize messages) }
    c
  end

  def self.wrap obj
    return obj if obj.is_a? Container
    return obj.root if obj.is_a? Thread
    return Container.new(obj.message_id, obj) if obj.is_a? Message or obj.is_a? Summary
    return Container.new(obj.message_id, obj) if obj.is_a? OpenStruct # test hack
    raise CantWrap, "Cannot wrap #{obj.class} in a Container"
  end

  def self.unwrap value_or_container
    return value_or_container.value if value_or_container.is_a? Container
    value_or_container
  end

  # Debugging --------------------------------------------------------

  def dump depth=0
    puts "  " * depth + "#{message.from} #{message.date.strftime('%m-%d')} #{message.call_number}"
    children.sort.each do |container|
      container.dump depth + 1
    end
    nil
  end

end

end # Chibrary
