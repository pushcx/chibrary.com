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
  def bool_reader *args
    args.each { |sym| class_eval %{ def #{sym}?; @#{sym}; end } }
  end
  def bool_writer *args; attr_writer(*args); end
  def bool_accessor *args
    bool_reader(*args)
    bool_writer(*args)
  end

  def defer_all_other_method_calls_to obj
    class_eval %{
      def method_missing meth, *a, &b; @#{obj}.send meth, *a, &b; end
      def respond_to? meth; @#{obj}.respond_to?(meth); end
    }
  end
end

module Enumerable
  def sum ; inject(0) { |x, y| x + y }; end

  def argfind
    ret = nil
    find { |e| ret ||= yield(e) }
    ret || nil # force
  end

  def argmin
    best, bestval = nil, nil
    each do |e|
      val = yield e
      if bestval.nil? || val < bestval
        best, bestval = e, val
      end
    end
    best
  end
end

# These two hashes replace SavingHash, which can't save and load its
# contructor proc.
class ContainerHash
  def initialize ; @hash = Hash.new ; end
  def [] k ; @hash[k] ||= Container.new(k) ; end
  defer_all_other_method_calls_to :hash
end
class LLThreadHash
  def initialize ; @hash = Hash.new ; end
  def [] k ; @hash[k] ||= LLThread.new ; end
  defer_all_other_method_calls_to :hash
end


class LLThread
  include Enumerable

  attr_reader :containers
  def initialize
    @containers = []
  end

  def << c
    @containers << c
  end

  def empty?; @containers.empty?; end
  def empty!; @containers.clear; end
  def drop c; @containers.delete(c) ; end #or raise "#{self}: bad drop #{c}"; end

  ## unused
  def dump f=$stdout
    f.puts "=== start thread with #{@containers.length} trees ==="
    @containers.each { |c| c.dump_recursive f }
    f.puts "=== end thread ==="
  end

  def count ; collect { |m, d, p| (m.instance_of? Message) ? 1 : 0 }.sum ; end

  ## yields each message, its depth, and its parent. the message yield
  ## parameter can be a Message object, or :fake_root, or nil (no
  ## message found but the presence of one induced from other
  ## messages).
  def each fake_root=false
    adj = 0
    root = @containers.find_all { |c| !Message.subject_is_reply?(c) }.argmin { |c| c.date || 0 }

    if root
      adj = 1
      root.first_useful_descendant.each_with_stuff do |c, d, par|
        yield c.message, d, (par ? par.message : nil)
      end
    elsif @containers.length > 1 && fake_root
      adj = 1
      yield :fake_root, 0, nil
    end

    @containers.each do |cont|
      next if cont == root
      fud = cont.first_useful_descendant
      fud.each_with_stuff do |c, d, par|
        ## special case here: if we're an empty root that's already
        ## been joined by a fake root, don't emit
        yield c.message, d + adj, (par ? par.message : nil) unless
          fake_root && c.message.nil? && root.nil? && c == fud 
      end
    end
  end

  def first; each { |m, *o| return m if m }; nil; end
  def date; map { |m, *o| m.date if m }.compact.max; end

  def size; map { |m, *o| m ? 1 : 0 }.sum; end
  def subject; argfind { |m, *o| m && Message.normalize_subject(m.subject) }; end

  def latest_message
    inject(nil) do |a, b| 
      b = b.first
      if a.nil?
        b
      elsif b.nil?
        a
      else
        b.date > a.date ? b : a
      end
    end
  end

  def to_s
    "<thread containing: #{@containers.join ', '}>"
  end
end

## recursive structure used internally to represent message trees as
## described by reply-to: and references: headers.
##
## the 'id' field is the same as the message id. but the message might
## be empty, in the case that we represent a message that was referenced
## by another message (as an ancestor) but never received.
class Container
  attr_accessor :message, :parent, :children, :id, :thread

  def initialize id
    raise "non-String #{id.inspect}" unless id.is_a? String
    @id = id
    @message, @parent, @thread = nil, nil, nil
    @children = []
  end      

  # Yield this and all child containers with depth and parent
  def each_with_stuff parent=nil
    yield self, 0, parent
    @children.each do |c|
      c.each_with_stuff(self) { |cc, d, par| yield cc, d + 1, par }
    end
  end

  # Containers are considered descendants of themselves
  def descendant_of? o
    if o == self
      true
    else
      @parent && @parent.descendant_of?(o)
    end
  end

  def == o; Container === o && @id == o.id; end

  def empty?; @message.nil?; end
  def root?; @parent.nil?; end
  def root; root? ? self : @parent.root; end

  def first_useful_descendant
    if empty? && @children.size == 1
      @children.first.first_useful_descendant
    else
      self
    end
  end

  def find_attr attr
    if empty?
      @children.argfind { |c| c.find_attr attr }
    else
      @message.send attr
    end
  end
  def subject; find_attr :subject; end
  def date   ; find_attr :date   ; end

  def is_reply?; subject && Message.subject_is_reply?(subject); end

  def to_s
    [ "<#{id}",
      (@parent.nil? ? nil : "parent=#{@parent.id}"),
      (@children.empty? ? nil : "children=#{@children.map { |c| c.id }.inspect}"),
    ].compact.join(" ") + ">"
  end

  def dump_recursive f=$stdout, indent=0, root=true, parent=nil
    raise "inconsistency" unless parent.nil? || parent.children.include?(self)
    unless root
      f.print " " * indent
      f.print "+->"
    end
    line = #"[#{useful? ? 'U' : ' '}] " +
      if @message
        "[#{thread}] #{@message.subject} " ##{@message.references.inspect} / #{@message.replytos.inspect}"
      else
        "<no message>"
      end

    f.puts "#{id} #{line}"#[0 .. (105 - indent)]
    indent += 3
    @children.each { |c| c.dump_recursive f, indent, false, self }
  end
end

## Builds thread structures, a set of threads.
##
## If 'thread_by_subject' is true, puts messages with the same subject in
## one thread, even if they don't reference each other. This is
## helpful for crappy MUAs that don't set In-reply-to: or References:
## headers, but means that messages may be threaded unnecessarily.
class ThreadSet
  attr_reader :num_messages, :threads
  bool_reader :thread_by_subject

  def self.month slug, year, month
    threadset = ThreadSet.new
    AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/thread/#{year}/#{month}/").each do |key|
      threadset.add_thread AWS::S3::S3Object.load_cache(key)
    end
    threadset
  end

  def initialize thread_by_subject=true
    @num_messages = 0
    ## map from message ids to container objects
    @messages = ContainerHash.new
    ## map from subject strings or (or root message ids) to thread objects
    @threads = LLThreadHash.new
    @thread_by_subject = thread_by_subject
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
    return if p == c || p.descendant_of?(c) || c.descendant_of?(p) # would create a loop

    if c.parent.nil? || overwrite
      c.parent.children.delete c if overwrite && c.parent
      if c.thread
        c.thread.drop c 
        c.thread = nil
      end
      p.children << c
      c.parent = p
    end
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

  ## merges in a pre-loaded thread
  def add_thread t
    raise "duplicate" if @threads.values.member? t
    t.each { |m, *o| add_message m }
  end

  def is_relevant? m
    m.references.any? { |ref_id| @messages.member? ref_id }
  end

  ## the heart of the threading code
  def add_message message
    el = @messages[message.message_id]
    return if el.message # we've seen it before

    el.message = message
    oldroot = el.root

    ## link via references:
    prev = nil
    message.references.each do |ref_id|
      ref = @messages[ref_id]
      link prev, ref if prev
      prev = ref
    end
    link prev, el, true if prev

    root = el.root

    ## new root. need to drop old one and put this one in its place
    if root != oldroot && oldroot.thread
      oldroot.thread.drop oldroot
      oldroot.thread = nil
    end

    key =
      if thread_by_subject?
        Message.normalize_subject root.subject
      else
        root.id
      end

    ## check to see if the subject is still the same (in the case
    ## that we first added a child message with a different
    ## subject)
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
