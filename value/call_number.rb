require 'adamantium'

module Chibrary

CALL_NUMBER_BITS = 47

class InvalidCallNumber < ArgumentError ; end

class CallNumber
  include Adamantium

  attr_reader :str

  def initialize str
    @str = (str || '').to_s
    raise InvalidCallNumber, "Invalid Call Number '#{@str}'" unless valid?
  end

  def valid?
    str =~ /\A[a-zA-Z0-9]{8}\z/
  end

  def == other
    to_s == other.to_s
  end
  alias :eql? :==

  def <=> other
    to_s <=> other.to_s
  end

  def hash
    to_s.hash
  end

  def to_s
    str
  end
  alias :to_str :to_s

  def inspect
    "<Chibrary::CallNumber:0x%x #{to_s}>" % (object_id << 1)
  end
end

end # Chibrary
