require_relative '../lib/time_'
require_relative 'message_container'
require_relative 'redirect_map'

# A ThreadSet holds the threads (container trees) and does the work of sorting
# messages into container trees.
# Main algorithm based on http://www.jwz.org/doc/threading.html

class ThreadSet
  include Enumerable

  attr_accessor :containers, :subjects, :redirect_map
  attr_reader :slug, :year, :month

  def initialize slug, year, month
    @slug, @year, @month = slug, year, month
    # @containers holds all containers, not just root-level containers
    # @containers is roughly id_table from JWZ's doc
    @containers = {} # message_id -> container
    @subjects = {}
    @redirect_map = RedirectMap.new @slug, @year, @month
    flush_threading
  end

  def == threadset
    return false if subjects.keys - threadset.subjects.keys != []
    return false if threadset.subjects.keys - subjects.keys != []
    subjects.each do |subject, container|
      return false if container != threadset.subjects[subject]
    end
    return false if @containers.keys - threadset.containers.keys != []
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
  def finish
    # build the cache if necessary
    return unless subjects.empty?

    # First, break parenting for messages that are lazy thread creation
    @containers.values.each do |container|
      # skip where there's not enough info to judge
      next if container.empty? or container.orphan? or container.parent.empty?
      container.orphan if container.message.likely_thread_creation_from? container.parent.message.email
    end

    @root_set = nil
    # Next, pick the likeliest thread roots.
    root_set.each do |container| # 5.4.B
      subject = container.n_subject
      existing = subjects.fetch(subject, nil)
      # This is more likely the thread root if...
      # 1. There is no existing root
      # 2. The existing root isn't empty and this one is
      # 3. The existing root has more re/fwd gunk on it
      subjects[subject] = container if !existing or (!existing.empty? and container.empty?) or container.subject_shorter_than? existing
    end

    # Next, move the rest of the same-subject roots under it.
    root_set.each do |container| # 5.4.C
      subject = container.n_subject
      existing = subjects.fetch(subject, nil)
      next if !existing or existing == container

      # If they're both dummies, let them share children.
      if container.empty? and existing.empty?
        container.children.clone.each do |child|
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
      elsif !existing.empty? and existing.subject_shorter_than? container
        existing.adopt container
      # Otherwise, they're either both replies to a missing, unreferenced
      # message (so make them siblings) or they just happened to share the
      # same subject, so... eh, make 'em siblings.
      else
        existing.adopt container
      end
    end

    # find proper parents for messages without references
    @containers.each do |message_id, container|
      next if container.empty? or container.root? or !container.message.references.empty?

      chosen_parent = container.parent
      direct_quotes = container.message.body.scan(/^> *[^>].+/).collect { |q| q.sub(/^> */, '') }

      # Loop through all containers to find the message with the most
      # matched quotes. (Can't just look through the existing container's
      # children, as this may be a reply to a reply that's also missing
      # its references but hasn't been sorted in yet.)
      best = 0
      @containers.each do |message_id, potential_parent|
        next if potential_parent.empty?
        next unless potential_parent.n_subject == container.n_subject
        next if message_id == container.message_id or potential_parent.child_of? container
        count = direct_quotes.collect { |q| (potential_parent.message.body.include? q) ? 1 : 0 }.inject(0, &:+)
        if count > best
          chosen_parent = potential_parent
          break if count == direct_quotes.size
        end
      end
      container.orphan
      chosen_parent.adopt container
    end
  end
  private :finish

  def plus_month n
    Time.utc(year, month).plus_month(n)
  end

  def prior_months
    (1..4).each { |n| yield plus_month(n) }
  end

  def following_months
    (1..4).each { |n| yield plus_month(-n) }
  end

  def retrieve_split_threads_from threadset
    return if @containers.empty?
    finish
    # subjects would be cleared as soon as a message is added and the threading is flushed
    # But we know there won't be any more subjects added, so just cache it
    subjects = root_set.collect(&:n_subject)
    threadset.each do |thread|
      next unless thread.likely_split_thread?
      next unless @containers.keys.include? thread.message_id or subjects.include? thread.n_subject

      # redirects?
      thread.each { |c| self << c.message unless c.empty? }
      threadset.redirect thread, year, month
    end
  end
  protected :retrieve_split_threads_from

  def each
    finish
    subjects.values.sort.each { |c| yield c }
  end

  def length
    finish
    subjects.length
  end

  def message_count include_empty=false
    count = 0
    # collect threads and their containers
    each do |thread|
      thread.each do |c|
        count += 1 if !c.empty? or include_empty
      end
    end
    count
  end

  def << message
    if @containers.has_key? message.message_id
      container = @containers[message.message_id]
      return unless container.empty? # message already stored; done
      container.message = message
    else
      container = MessageContainer.new(message.message_id, message)
      @containers[message.message_id] = container
    end

    # references are sorted oldest -> youngest
    # walk this container's references and parent them
    previous = nil
    message.references.each do |message_id|
      if @containers.has_key? message_id
        child = @containers[message_id]
      else
        child = MessageContainer.new(message_id)
        @containers[message_id] = child
      end
      previous.adopt child if previous
      previous = child
    end
    # The last reference is trusted to be the parent of this message,
    # but once we have all the messages we confirm.
    previous.adopt container if previous

    flush_threading
  end

  def flush_threading
    # clear everything computed by finish
    @subjects    = {} # threads: normalized subject -> root container
    @root_set   = nil
  end

  def redirect thread, year, month
    @redirect_map.redirect thread.collect(&:call_number), year, month
    thread.each { |c| @containers.delete(c.message_id) }
    flush_threading
  end
  protected :redirect

  def to_s
    "ThreadSet #{@slug}/#{@year}/#{@month}"
  end

  def dump
    finish
    puts
    puts "#{self}:"
    #puts "subjects: "
    #subjects.each do |subject, container|
    #  puts "#{subject}  ->  #{container.message_id}"
    #end
    #puts "threads: "
    each do |container|
      puts container.subject
      container.dump
      puts
    end
  end
end
