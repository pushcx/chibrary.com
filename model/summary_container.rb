# based on http://www.jwz.org/doc/threading.html

require_relative '../lib/container'
require_relative '../value/summary'
require_relative 'message_container'

module Chibrary

class SummaryContainer
  include Container

  def initialize message_id, message=nil
    super
  end

  alias :message  :value
  alias :message_id :key

  def slug
    effective_field(:slug)
  end

  def call_number
    effective_field(:call_number) or ''
  end

  def date
    effective_field(:date) or Time.now
  end

  def n_subject
    effective_field(:n_subject) or ''
  end

  def blurb
    effective_field(:blurb) or ''
  end

  def summarize
    self
  end

  def messagize messages
    c = MessageContainer.new key, messages[call_number]
    children.each { |child| c.adopt(child.messagize messages) }
    c
  end

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<SummaryContainer(#{key}): #{v}>"
  end
end

end # Chibrary
