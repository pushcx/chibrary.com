require 'adamantium'

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
    str =~ /\A[a-zA-Z0-9]{8}\Z/
  end

  def == other
    to_s == other.to_s
  end

  def eql? other
    self == other
  end

  def hash
    to_s.hash
  end

  def to_s
    str
  end
end
