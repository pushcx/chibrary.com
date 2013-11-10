# based on http://www.jwz.org/doc/threading.html

require 'active_support/core_ext/enumerable'

# Each container holds 0 or 1 messages, so that we can build a thread's tree from
# References and In-Reply-To headers even before seeing all of the messages.
class Container
  include Enumerable

  attr_reader :message_id, :parent, :children

  def initialize message, message_key=nil
    if message.is_a? Message
      @message_id = message.message_id
      @message    = message
      @message_key        = (message_key || message.key)
    else
      @message_id = message
      @message    = nil
      @message_key        = message_key
    end
    @parent = nil
    @children = []
  end

  def to_yaml_properties ; %w{@message_id @message_key @parent @children}.sort! ; end
  def to_hash
    {
      class: 'Container',
      message_id: @message_id,
      message_key: @message_key,
      children: children.map(&:to_hash),
    }
  end

  def self.deserialize hash
    container = self.new hash['message_id'], hash['message_key']
    hash['children'].each do |child|
      container.adopt Container.deserialize(child)
    end
    container
  end

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
    empty? or message.subject_is_reply? or effective_field(:body) =~ /^[>\|] .+/
  end

  def message
    # To save disk, threads do not save full message contents,
    # just lazy load them when needed.
    @message ||= $riak[@message_key] if @message_key
    @message
  end

  def message= message
    raise "Message id #{message.message_id} doesn't match container #{@message_id}" unless message.message_id == @message_id
    @message_id  = message.message_id
    @message     = message
    @message_key = message.key
  end

  def subject_shorter_than? container
    return subject.length < container.subject.length
  end

  def to_s
    return "<empty container>" if empty?
    return "#{message.from} - #{message.date} - #{message_id}" unless message.nil?
    return "<container: #{message_id} - #{message_key}>"
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
    hash = self.to_hash
    begin
      return if $riak.sizeof(key) == hash.to_json.size
    rescue NotFound ; end

    $riak[key] = hash
    cache_snippet
  end

  def cache_snippet
    return if n_subject.blank?
    return if date > Time.now.utc
    slug = effective_field(:slug)

    # names are descending time to make it easy to expire old snippets
    name = 9999999999 - date.utc.to_i
    snippet = {
      :url => "/#{slug}/#{date.year}/#{"%02d" % date.month}/#{call_number}",
      :subject => n_subject,
      :excerpt => (effective_field(:body) or "").split("\n").select { |l| not (l.chomp.empty? or l =~ /^>|@|:$/) }[0..4].join(" "),
    }

    # Don't write snippet if it won't be in top 30. It would be cleaned up,
    # but loading old archives could exhaust the available inodes.
    return if last_snippet_key("snippet/list/#{slug}").to_i > name
    $riak["snippet/list/#{slug}/#{name}"] = snippet
    return if last_snippet_key("snippet/homepage").to_i > name
    $riak["snippet/homepage/#{name}"] = snippet
  end

  def last_snippet_key path
    last_key = 0
    begin
      $riak[path].each_with_index { |key, i| last_key = key ; break if i >= 30 }
    rescue NotFound ; end
    return last_key
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
