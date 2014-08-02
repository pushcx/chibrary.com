module Chibrary

# Each container holds 0 or 1 values and any number of child containers.
# The value is optional so that I can build thread trees even before seeing
# all messages (based on References and In-Reply-To).
module Container
  include Enumerable

  attr_reader :key, :value, :parent, :children

  def initialize key, value=nil
    @key = key
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
  
  def <=> other
    key <=> other.key
  end

  def each#(&block)
    # yield this container
    yield self
    children.sort!
    # TODO: simpler?
    #@children.each(&block) do |child|
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

  def value= value
    raise "Can't reassign value #{value} of non-empty container #{key}" unless empty?
    @value = value
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

  # debugging
  def dump depth=0
    puts "  " * depth + self.to_s
    children.each do |container|
      container.dump depth + 1
    end
  end
end

end # Chibrary
