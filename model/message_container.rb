# based on http://www.jwz.org/doc/threading.html

require_relative '../lib/container'
require_relative '../value/summary'
require_relative 'summary_container'

class MessageContainer
  include Container

  def initialize message_id, message=nil
    super
  end

  def <=> container
    date <=> container.date
  end

  def adopt container
    # Don't adopt any messages that already have parents (that is, they're
    # threaded). A message with a malicious References header should not be
    # able to reparent other messages willy-nilly, but we do trust a message
    # to report its own parent.
    return unless container.orphan? or (!container.empty? and container.value.references.last == message_id)
    super
  end

  def likely_split_thread?
    message and message.likely_split_thread?
  end

  def value= message
    raise "Message id #{message.message_id} doesn't match container #{key}" unless message.message_id == message_id
    super
  end

  alias :message= :value=
  alias :message  :value
  alias :message_id :key

  def subject_shorter_than? container
    return subject.length < container.subject.length
  end

  def slug
    effective_field(:slug)
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

  def summarize
    summary = Summary.from(value)
    if value.no_archive?
      c = SummaryContainer.new key
    else
      c = SummaryContainer.new key, summary
    end
    children.each { |child| c.adopt(child.summarize) }
    c
  end

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<MessageContainer(#{key}): #{v}>"
  end
end
