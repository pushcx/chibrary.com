require 'adamantium'

class MessageId
  include Adamantium

  attr_reader :raw

  def initialize raw
    @raw = (raw || '').to_s
  end

  def valid?
    !raw.empty? and raw.length <= 120 and has_id?
  end
  
  def has_id?
    raw =~ /\A<?[a-zA-Z0-9%+\-\.=_]+@[a-zA-Z0-9_\-\.]+>?\Z/
  end

  def to_s
    if valid?
      /^<?([^@]+@[^\>]+)>?/.match(raw)[1].chomp
    else
      "[invalid or missing message id]"
    end
  end

  def == other
    other = MessageId.new(other)
    return false unless valid? and other.valid?
    to_s == other.to_s
  end

  def eql? other
    self == other
  end

  def encoding
    to_s.encoding
  end

  def hash
    to_s.hash
  end

  def inspect
    "#<MessageId:%x '%s'>" % [(object_id << 1), to_s]
  end

  def self.generate_for call_number
    new "#{call_number}@generated-message-id.chibrary.org"
  end
end
