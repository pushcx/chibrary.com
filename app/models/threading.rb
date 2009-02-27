# based on http://www.jwz.org/doc/threading.html

require 'storage'
require 'message'

# Each container holds 0 or 1 messages, so that we can build a thread's tree from
# References and In-Reply-To headers even before seeing all of the messages.
class Container
  include Enumerable

  attr_reader :message_id, :parent, :children

  def initialize message
    if message.is_a? Message
      @message_id = message.message_id
      @message    = message
      @key        = message.key
    else
      @message_id = message
      @message    = nil
      @key        = nil
    end
    @parent = nil
    @children = []
  end

  def to_yaml_properties ; %w{@message_id @key @parent @children}.sort! ; end

  # container accessors

  def == container
    container.is_a? Container and @message_id == container.message_id
  end

  def <=> container
    date <=> container.date
  end

  def count
    # count of messages, not just containers
    collect { |c| 1 unless c.empty? }.compact.sum
  end

  def depth
    if root?
      0
    else
      @parent.depth + 1
    end
  end

  def empty?
    message.nil?
  end

  def likely_split_thread?
    empty? or message.subject_is_reply?
  end

  def message
    # To save disk, threads do not save full message contents,
    # just lazy load them when needed.
    @message ||= $archive[@key] if @key
    @message
  end

  def message= message
    raise "Message id #{message.message_id} doesn't match container #{@message_id}" unless message.message_id == @message_id
    @message_id = message.message_id
    @message    = message
    @key        = message.key
  end

  def subject_shorter_than? container
    return subject.length < container.subject.length
  end

  def to_s
    (empty? ? "<empty container>" : "#{message.from} - #{message.date}") + " - #{message_id}"
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
    # yield this container
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
  def call_number
    effective_field :call_number or ''
  end
  def date
    effective_field :date or Time.now
  end
  def subject
    effective_field :subject or ''
  end
  def n_subject
    effective_field :n_subject or ''
  end

  def empty_tree?
    # a thread of dummy containers is not worth saving
    each { |container| return false unless container.empty? }
    return true
  end

  # persistence

  def key
    slug = effective_field :slug
    key = "list/#{slug}/thread/#{date.year}/%02d/#{call_number}" % date.month
  end

  def cache
    return if empty_tree?
    yaml = self.to_yaml
    begin
      return if $archive[key].to_yaml.size == yaml.size
    rescue NotFound ; end

    $archive[key] = yaml
    cache_snippet
  end

  def cache_snippet
    return if n_subject.blank?
    return if date.utc > Time.now.utc
    # names are descending time to make it easy to expire old snippets
    name = 9999999999 - date.utc.to_i
    snippet = {
      :url => "/#{effective_field(:slug)}/#{date.year}/#{"%02d" % date.month}/#{call_number}",
      :subject => n_subject,
      :excerpt => (effective_field(:body) or "").split("\n").select { |l| not (l.chomp.empty? or l =~ /^>|@|:$/) }[0..4].join(" "),
    }
    $archive["snippet/homepage/#{name}"] = snippet
    $archive["snippet/list/#{effective_field(:slug)}/#{name}"] = snippet
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

  attr_accessor :containers
  attr_reader :slug, :year, :month

  def self.month slug, year, month
    threadset = ThreadSet.new(slug, year, month)
    return threadset unless $archive.has_key? "list/#{slug}/thread/#{year}/#{month}"
    threads = $archive["list/#{slug}/thread/#{year}/#{month}"]
    threads.each do |key|
      thread = threads[key]
      thread.each { |c| threadset.containers[c.message_id] = c }
    end
    threadset
  end

  def initialize slug, year, month
    @slug, @year, @month = slug, year, month
    # @containers holds all containers, not just root-level containers
    # @containers is roughly id_table from JWZ's doc
    @containers = {} # message_id -> container
    @redirected_threads = []
    flush_threading
  end

  def subjects ; @subjects ; end
  protected :subjects

  def == threadset
    return false if @subjects.keys - threadset.subjects.keys != []
    return false if threadset.subjects.keys - @subjects.keys != []
    @subjects.each do |subject, container|
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
    return unless @subjects.empty?

    # First, break parenting for messages that are lazy thread creation
    @containers.values.each do |container|
      # skip where there's not enough info to judge
      next if container.empty? or container.orphan? or container.parent.empty?
      container.orphan if container.message.likely_lazy_reply_to? container.parent.message
    end

    @root_set = nil
    # Next, pick the likeliest thread roots.
    root_set.each do |container| # 5.4.B
      subject = container.n_subject
      existing = @subjects.fetch(subject, nil)
      # This is more likely the thread root if...
      # 1. There is no existing root
      # 2. The existing root isn't empty and this one is
      # 3. The existing root has more re/fwd gunk on it
      @subjects[subject] = container if !existing or (!existing.empty? and container.empty?) or container.subject_shorter_than? existing
    end

    # Next, move the rest of the same-subject roots under it.
    root_set.each do |container| # 5.4.C
      subject = container.n_subject
      existing = @subjects.fetch(subject, nil)
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
        chosen_parent = existing
        if !container.empty? and container.message.references.empty?
          # It's a reply without references, use quoting to find its parents
          direct_quotes = container.message.body.scan(/^> [^>].+/).collect { |q| q.sub(/^> /, '') }
          # Loop through all containers to find the message with the most
          # matched quotes. (Can't just look through the existing container's
          # children, as this may be a reply to a reply that's also missing
          # its references but hasn't been sorted in yet.)
          best = 0
          @containers.each do |message_id, potential_parent|
            next if potential_parent.empty?
            next unless potential_parent.n_subject == container.n_subject
            next if message_id == container.message_id
            count = direct_quotes.collect { |q| 1 if potential_parent.message.body.include? q }.compact.sum
            if count > best
              chosen_parent = potential_parent
              break if count == direct_quotes.size
            end
          end
        end
        chosen_parent.adopt container
      # Otherwise, they're either both replies to a missing, unreferenced
      # message (so make them siblings) or they just happened to share the
      # same subject, so... eh, make 'em siblings.
      else
        c = Container.new(existing.message_id + container.message_id)
        c.adopt existing
        c.adopt container
        @containers[c.message_id] = c
        @subjects[c.n_subject] = c
      end
    end
  end
  private :finish

  def rejoin_splits
    # Many threads are split by replies in later months. This is separate from
    # finish and must be explicitly called to prevent the infinite loops that
    # would otherwise result as ThreadSets store (which requires a call to
    # finish) each other.

    # Rejoin any threads from later months
    (1..6).each do |n|
      retrieve_split_threads_from plus_month(n)
    end
    # And move threads up to earlier months when possible
    (-6..-1).each do |n|
      plus_month(n).retrieve_split_threads_from self
    end
  end

  def retrieve_split_threads_from threadset
    return if @containers.empty?
    finish
    threadset.each do |thread|
      next unless thread.likely_split_thread?
      next unless @containers.keys.include? thread.message_id or @subjects.include? thread.n_subject

      # redirects?
      thread.each { |c| self << c.message unless c.empty? }
      threadset.redirect thread, year, month
    end

    threadset.store
    store
  end
  protected :retrieve_split_threads_from

  def plus_month n
    t = Time.utc(@year, @month).plus_month(n)
    ThreadSet.month(@slug, t.year, '%02d' % t.month)
  end

  def each
    finish
    @subjects.values.sort.each { |c| yield c }
  end

  def length
    finish
    @subjects.length
  end

  def message_count include_empty=false
    # collect threads and their containers
    collect do |thread|
      thread.collect do |c|
        c if !c.empty? or include_empty
      end.compact
    end.flatten.size
  end

  def store
    finish
    # cache each thread
    thread_list = ThreadList.new(@slug, @year, @month)
    each do |thread|
      thread.cache
      thread_list.add_thread thread
    end
    @redirected_threads.each do |redirect|
      thread_list.add_redirected_thread *redirect
    end
    thread_list.store
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
    # The last reference is trusted to be the parent of this message,
    # but once we have all the messages we confirm.
    previous.adopt container if previous

    flush_threading
  end

  def flush_threading
    # clear everything computed by finish
    @subjects    = {} # threads: normalized subject -> root container
    @root_set    = nil
  end

  def redirect thread, year, month
    # note redirection
    @redirected_threads << [thread.collect(&:call_number).uniq, year, month]

    # remove from this storage
    $archive.delete(thread.key)
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
    #@subjects.each do |subject, container|
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
