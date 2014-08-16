require 'adamantium'

module Chibrary

class Sy
  include Adamantium

  attr_reader :slug, :year

  def initialize slug, year
    @slug, @year = slug, year.to_i
  end

  def to_key
    "#{slug}/#{year}"
  end
  alias :to_s :to_key

  def inspect
    "<Chibrary::Sy:0x%x #{to_s}'>" % (object_id << 1)
  end
end

end # Chibrary
