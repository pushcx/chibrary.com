# GPLv2

## At the top level, we have a ThreadSet. A ThreadSet represents a set
## of threads, e.g. a message folder or an inbox. Each ThreadSet
## contains zero or more LLThreads. A LLThread represents all the message
## related to a particular subject. Each LLThread has one or more
## Containers. A Container is a recursive structure that holds the
## tree structure as determined by the references: and in-reply-to:
## headers. A LLThread with multiple Containers occurs if they have the
## same subject, but (most likely due to someone using a primitive
## MUA) we don't have evidence from in-reply-to: or references:
## headers, only subject: (and thus our tree is probably broken). A
## Container holds zero or one message. In the case of no message, it
## means we've seen a reference to the message but haven't seen the
## message itself (yet).

require 'message'

class Module
  def defer_all_other_method_calls_to obj
    class_eval %{
      def method_missing meth, *a, &b; @#{obj}.send meth, *a, &b; end
      def respond_to? meth; @#{obj}.respond_to?(meth); end
    }
  end
end

# These two hashes replace SavingHash, which can't save and load its
# contructor proc.
class ContainerHash
  def initialize ; @hash = Hash.new ; end
  def [] key ; @hash[key] ||= Container.new(key) ; end
  defer_all_other_method_calls_to :hash
end
class LLThreadHash
  def initialize ; @hash = Hash.new ; end
  def [] key ; @hash[key] ||= LLThread.new ; end
  defer_all_other_method_calls_to :hash
end

# Each container holds 0 or 1 messages, so that we can build a thread's tree from
# References and In-Reply-To headers even before seeing all of the messages.
class Container
  attr_accessor :message, :parent, :children, :id, :thread

  def initialize id
    raise "non-String #{id.inspect}" unless id.is_a? String
    @id = id
    @message, @parent, @thread = nil, nil, nil
    @children = []
  end      

  def each
    # yeild this continer
    yield self
    @children.each do |c|
      # and yield what all children containers yield
      c.each { |cc| yield cc }
    end
  end

  # Containers are considered descendants of themselves
  def descendant_of? o
    if o == self
      true
    else
      @parent and @parent.descendant_of?(o)
    end
  end

  def == container
    Container === container and @id == container.id
  end

  def empty?
    @message.nil?
  end

  def root?
    @parent.nil?
  end

  def root
    if root?
      self
    else
      @parent.root
    end
  end

  # The effective root of the container tree is the first container with a
  # message or with multiple children (meaning we've seen it referenced from
  # multiple messages).
  def effective_root
    if empty? and @children.size == 1
      @children.first.effective_root
    else
      self
    end
  end

  # Find the attribute in the first container with a message.
  def find_attr attr
    if empty?
      @children.argfind { |c| c.find_attr attr }
    else
      @message.send attr
    end
  end
  def subject; find_attr :subject; end
  def date   ; find_attr :date   ; end

  def to_s
    [ "<container #{id}",
      (@parent.nil?     ? nil : "parent=#{@parent.id}"),
      (@children.empty? ? nil : "children=#{@children.map { |c| c.id }.inspect}"),
    ].compact.join(" ") + ">"
  end

  def dump indent=0, root=true, parent=nil
    raise "inconsistency" unless parent.nil? || parent.children.include?(self)
    unless root
      $stdout.print " " * indent
      $stdout.print "+->"
    end
    line = #"[#{useful? ? 'U' : ' '}] " +
      if @message
        "[#{thread}] #{@message.subject} " ##{@message.references.inspect} / #{@message.replytos.inspect}"
      else
        "<no message>"
      end

    $stdout.puts "#{id} #{line}"#[0 .. (105 - indent)]
    indent += 3
    @children.each { |c| c.dump indent, false, self }
  end
end

class LLThread
  include Enumerable

  attr_reader :containers

  def initialize
    @containers = []
  end

  def << c
    @count = nil
    @containers << c
  end

  def empty?
    @containers.empty?
  end

  def empty!
    @containers.clear
    @count = nil
  end

  def drop c
    @containers.delete(c)
    @count = nil
  end #or raise "#{self}: bad drop #{c}"; end

  def each_container
    @containers.each do |container|
      container.each { |c| yield c }
    end
  end

  def each # Each message, that is
    @containers.each do |container|
      container.each { |c| yield c.message unless c.empty? }
    end
  end

  def count
    @count ||= collect { 1 }.sum
  end

  def first
    each { |m| return m }
    nil
  end

  def call_number
    first.call_number if first
  end

  def to_s
    "<thread with containers: #{@containers.join ', '}>"
  end

  def dump
    $stdout.puts "=== start thread with #{@containers.length} trees ==="
    @containers.each { |c| c.dump }
    $stdout.puts "=== end thread ==="
  end
end

## Builds thread structures, a set of threads.
class ThreadSet
  attr_reader :num_messages, :threads

  def self.month slug, year, month
    threadset = ThreadSet.new
    AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/thread/#{year}/#{month}/").each do |key|
      threadset.add_thread AWS::S3::S3Object.load_yaml(key)
    end
    threadset
  end

  def initialize
    @num_messages = 0
    ## map from message ids to container objects
    @messages = ContainerHash.new
    ## map from subject strings or (or root message ids) to thread objects
    @threads = LLThreadHash.new
  end

  def contains_id? id; @messages.member?(id) && !@messages[id].empty?; end
  def thread_for m
    (c = @messages[m.message_id]) && c.root.thread
  end

  def delete_cruft
    @threads.each { |k, v| @threads.delete(k) if v.empty? }
  end
  private :delete_cruft

  def threads; delete_cruft; @threads.values; end
  def size; delete_cruft; @threads.size; end

  ## unused
  def dump f=$stdout
    @threads.each do |s, t|
      f.puts "** subject: #{s}"
      t.dump f
    end
    nil
  end

  def link p, c, overwrite=false
    # don't create loops
    return if p == c or c.descendant_of?(p) or p.descendant_of?(c)
    # don't overwrite c's parent unless requested
    return unless c.parent.nil? or overwrite

    c.parent.children.delete c unless c.parent.nil?
    if c.thread
      c.thread.drop c 
      c.thread = nil
    end
    p.children << c
    c.parent = p
  end
  private :link

  def remove mid
    return unless(c = @messages[mid])

    c.parent.children.delete c if c.parent
    if c.thread
      c.thread.drop c
      c.thread = nil
    end
  end

  # extract messages from a thread and add them
  def add_thread thread
    raise "duplicate" if @threads.values.member? thread
    thread.each { |m| add_message m }
  end

  ## the heart of the threading code
  def add_message message
    return unless message.is_a? Message

    # Fetch/create the message's container
    container = @messages[message.message_id]
    # Already threaded if the container already has the message
    return if container.message

    container.message = message
    # save the thread root, which this message may replace
    oldroot = container.root

    # link via references:
    prev = nil
    message.references.each do |id|
      ref = @messages[id]
      link prev, ref if prev
      prev = ref
    end
    link prev, container, true if prev

    root = container.root

    # this message is the new root; clean up the old
    if container.root? && oldroot.thread
      oldroot.thread.drop oldroot
      oldroot.thread = nil
    end

    key = Message.normalize_subject root.subject

    # check to see if the subject is still the same (in the case
    # that we first added a child message with a different
    # subject)
    if root.thread
      unless @threads[key] == root.thread
        if @threads[key]
          root.thread.empty!
          @threads[key] << root
          root.thread = @threads[key]
        else
          @threads[key] = root.thread
        end
      end
    else
      thread = @threads[key]
      thread << root
      root.thread = thread
    end

    ## last bit
    @num_messages += 1
  end
end
