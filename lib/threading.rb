# based on http://www.jwz.org/doc/threading.html

require 'message'

# Each container holds 0 or 1 messages, so that we can build a thread's tree from
# References and In-Reply-To headers even before seeing all of the messages.
class Container
  include Enumerable

  attr_reader :message_id, :message, :parent, :children

  def initialize message
    if message.is_a? Message
      @message_id = message.message_id
      @message    = message
    else
      @message_id = message
      @message    = nil
    end
    @parent = nil
    @children = []
  end      

  # container accessors

  def == container
    container.is_a? Container and @message_id == container.message_id
  end

  def <=> container
    date <=> container.date
  end

  def empty?
    @message.nil?
  end

  def to_s
    (empty? ? "<empty container>" : "#{@message.from} - #{@message.date}") + " - #{@message_id}"
  end

  # parentage accessors

  def child_of? c
    return (c == self or (@parent and @parent.child_of? c))
  end

  def root?
    @parent.nil?
  end
  # Different context, same effects
  alias :orphan? :root?

  def root
    if root?
      self
    else
      @parent.root
    end
  end

  def each
    # yeild this container
    yield self
    @children.sort!
    @children.each do |child|
      # and yield what all children containers yield
      child.each { |y| yield y }
    end
  end

  # A thread may have empty containers at its root as containers are created from References.
  # The effective root is the first container with a # message or with multiple
  # children (meaning we've seen it referenced from multiple messages).
  def effective_root
    if empty? and @children.size == 1
      @children.first.effective_root
    else
      self
    end
  end

  # When asked for subject or date, return the earliest available.
  def effective_field field
    each do |container|
      return container.message.send(field) unless container.empty?
    end
    nil
  end
  def subject
    effective_field :subject or ''
  end
  def n_subject
    effective_field :n_subject or ''
  end
  def date
    effective_field :date or Time.now
  end

  # parenting methods

  # Break the parent -> child relationship pointing to this container.
  def orphan
    @parent.disown self if @parent
    @parent = nil
  end

  # Call #orphan on the child and it will call this. If you call this instead
  # of #orphan, the child will have a lingering bad pointer to this container
  # as a parent.
  def disown container
    @children.delete container
  end
  protected :disown

  def parent= container
    @parent = container
  end
  protected :parent=

  def message= m
    raise "Message id #{m.message_id} doesn't match container #{@message_id}" unless m.message_id == @message_id
    @message = m
  end

  # Make this the parent of another container.
  def adopt container
    return if container.child_of?(self) or self.child_of?(container)
    # Don't adopt any messages that already have parents (that is, they're threaded).
    # A message with a malicious References header should not be able to reparent
    # other messages willy-nilly, but we do trust a message to report its own parent.
    return unless container.orphan? or (container.message and container.message.references.last == @message_id)

    container.orphan
    @children << container
    container.parent = self
  end

  # debugging

  def dump depth=0
    puts "  " * depth + self.to_s
    @children.each do |container|
      container.dump depth + 1
    end
  end
end

# A ThreadSet holds the threads (container trees) and does the work of sorting
# messages into container trees.
class ThreadSet
  include Enumerable

  attr_reader :containers

  def self.month slug, year, month
    threadset = ThreadSet.new
    AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/messages/#{year}/#{month}/").each do |key|
      AWS::S3::S3Object.load_yaml(key).each do |container|
        threadset << container
      end
    end
    threadset
  end

  def initialize
    # @containers holds all containers, not just root-level containers
    # @containers is roughly id_table from JWZ's doc
    @containers = {} # message_id -> container
    @subjects   = {} # threads: normalized subject -> root container
    @root_set = nil
  end

  def subjects ; @subjects ; end
  protected :subjects

  def == threadset
    #puts "testing =="
    #puts "threadset has subjects key we don't" if @subjects.keys - threadset.subjects.keys != []
    return false if @subjects.keys - threadset.subjects.keys != []
    #puts "we have subjects key threadset doesn't" if threadset.subjects.keys - @subjects.keys != []
    return false if threadset.subjects.keys - @subjects.keys != []
    @subjects.each do |subject, container|
      return false if container != threadset.subjects[subject]
    end
    #puts "threadset has containers key we don't" if @containers.keys - threadset.containers.keys != []
    return false if @containers.keys - threadset.containers.keys != []
    #puts "threadset has containers key we don't" if threadset.containers.keys - @containers.keys != []
    return false if threadset.containers.keys - @containers.keys != []
    @containers.each do |message_id, container|
      return false if container != threadset.containers[message_id]
    end
    true
  end

  # yield the root set of containers
  def root_set
    @root_set ||= @containers.values.select { |c| c.root? }
  end
  private :root_set

  # finish the threading and yield each root container (thread) in turn
  def each
    # build the cache if necessary
    if @subjects.empty?
      # First, pick the likeliest thread roots.
      root_set.each do |container| # 5.4.B
        subject = container.n_subject
        existing = @subjects.fetch(subject, nil)
        # This is more likely the thread root if...
        # 1. There is no existing root
        # 2. The existing root isn't empty and this one is
        # 3. The existing root has more re/fwd gunk on it
        @subjects[subject] = container if !existing or (!existing.empty? and container.empty?) or existing.subject.length > container.subject.length
      end
      # Next, move the rest of the same-subject roots under it.
      root_set.each do |container| # 5.4.C
        subject = container.n_subject
        existing = @subjects.fetch(subject, nil)
        next if !existing or existing == container

        # If they're both dummies, let them share children.
        if container.empty? and existing.empty?
          container.children.each do |child|
            child.orphan
            existing.adopt child
          end
          @containers.delete container.message_id
        # If one is empty, assume it's the parent of the other
        elsif container.empty? and !existing.empty?
          container.adopt existing
        elsif !container.empty? and existing.empty?
          existing.adopt container
        # If the existing isn't empty and isn't a reply, make this a child (converse is handled in 3. above)
        elsif !existing.empty? and existing.subject.length <= container.subject.length
          existing.adopt container
        # Otherwise, they're either both replies to a missing, unreferenced
        # message (so make them siblings).
        # Or they just happened to share the same subject, so... eh, make 'em
        # siblings.
        else
          c = Container.new(existing.message_id + container.message_id)
          c.adopt existing
          c.adopt container
          @containers[c.message_id] = c
          @subjects[c.n_subject] = c
        end
      end
    end
    @subjects.values.sort.each { |c| yield c }
  end

  def << message
    if @containers.has_key? message.message_id
      container = @containers[message.message_id]
      return unless container.empty? # message already stored; done
      container.message = message
    else
      container = Container.new(message)
      @containers[message.message_id] = container
    end

    # references are sorted oldest -> youngest
    # walk this container's references and parent them
    previous = nil
    message.references.each do |message_id|
      if @containers.has_key? message_id
        child = @containers[message_id]
      else
        child = Container.new(message_id)
        @containers[message_id] = child
      end
      previous.adopt child if previous
      previous = child
    end
    # the last reference is trusted to be the parent of this message
    previous.adopt container if previous

    @subjects = {} # clear top-level thread cache
    @root_set = nil
  end

  def dump
    puts
    puts "subjects: "
    @subjects.each do |subject, container|
      puts "#{subject}  ->  #{container.message_id}"
    end
    puts "threads: "
    each do |container|
      puts
      puts container.subject
      container.dump
    end
  end
end
