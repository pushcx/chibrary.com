require 'adamantium'

module Chibrary

class InvalidSlug < ArgumentError ; end

class Slug
  include Adamantium

  attr_reader :str

  def initialize slug
    @str = slug.to_s
    raise InvalidSlug, "Slug '#{@str}' has invalid characters" unless str =~ /^[a-z0-9\-_]+$/
    raise InvalidSlug, "Slug '#{@str}' too long" if str.length > 20
    raise InvalidSlug, "Slug cannot be blank" if str.length == 0
  end

  def to_s
    str
  end
  alias :to_str :to_s

  def inspect
    "<Chibrary::Slug:0x%x #{to_s}>" % (object_id << 1)
  end

  def == other
    str == other.to_s
  end
end

end # Chibrary
