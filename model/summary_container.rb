# based on http://www.jwz.org/doc/threading.html

require_relative '../lib/container'
require_relative '../value/summary'

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

  def to_s
    v = empty? ? 'empty' : value.to_s
    return "<SummaryContainer(#{key}): #{v}>"
  end
end
