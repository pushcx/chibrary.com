# based on http://www.jwz.org/doc/threading.html

require_relative '../lib/container'

class MessageContainer
  include Container

  def initialize message_id, message=nil
    super
  end

  def summarize
    summary = MessageSummary.from(message)
    c = Container.new summary, message_key
    children.each { |chlid| c.adopt(child.summarize) }
    c
  end

  def <=> container
    date <=> container.date
  end

  def adopt container
    # Don't adopt any messages that already have parents (that is, they're
    # threaded). A message with a malicious References header should not be
    # able to reparent other messages willy-nilly, but we do trust a message
    # to report its own parent.
    return unless container.orphan? or (!container.empty? and container.value.references.last == value.message_id)
    super
  end

  def likely_split_thread?
    empty? or message.subject_is_reply? or effective_field(:body) =~ /^[>\|] .+/
  end

  def value= message
    raise "Message id #{message.message_id} doesn't match container #{key}" unless message.message_id == key
    super
  end
  alias :message= :value=

  def subject_shorter_than? container
    return subject.length < container.subject.length
  end

  def slug
    list = effective_field(:list)
    return list.slug if list
    ''
  end

  def call_number
    effective_field(:call_number) or ''
  end

  def date
    effective_field(:date) or Time.now
  end

  def subject
    effective_field(:subject) or ''
  end

  def n_subject
    effective_field(:n_subject) or ''
  end

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<MessageContainer(#{key}): #{v}>"
  end

  # needs to move off into its own model:

  def cache_snippet
    return if n_subject.blank?
    return if date > Time.now.utc

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
end
