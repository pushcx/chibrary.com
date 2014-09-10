require 'adamantium'

require_relative '../lib/core_ext/time_'
require_relative 'slug'
require_relative 'sy'

module Chibrary

class Sym
  include Adamantium

  attr_reader :slug, :year, :month

  def initialize slug, year, month
    @slug, @year, @month = Slug.new(slug), year.to_i, month.to_i
    raise ArgumentError, "Invalid year '#{@year}'" unless @year.to_s =~ /\A\d{4}\Z/
    raise ArgumentError, "Invalid month" unless (1..12).include? @month
  end

  def same_time_as? sym
    sym.year == year and sym.month == month
  end

  def plus_month n
    t = Time.utc(year, month).plus_month(n)
    Sym.new slug, t.year, t.month
  end

  def to_key
    "#{slug}/#{year}/%02d" % month
  end
  alias :to_s :to_key

  # breaks the general pattern to have this here rather than Sy.from_sym, but
  # the code looks nicer
  def to_sy
    Sy.new slug, year
  end

  def == other
    other.slug == slug and same_time_as? other
  end
  alias :eql? :==

  def hash
    to_key.hash
  end

  def inspect
    "<Chibrary::Sym:0x%x #{to_s}'>" % (object_id << 1)
  end

  def self.from_container container
    new container.slug, container.date.year, container.date.month
  end
end

end # Chibrary
