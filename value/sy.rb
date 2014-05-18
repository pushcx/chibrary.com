require 'adamantium'

class Sy
  include Adamantium

  attr_reader :slug, :year

  def initialize slug, year
    @slug, @year = slug, year.to_i
  end

  def to_key
    "#{slug}/#{year}"
  end
end
