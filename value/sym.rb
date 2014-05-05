require_relative '../lib/core_ext/time_'
require_relative 'sy'

class Sym
  attr_reader :slug, :year, :month

  def initialize slug, year, month
    @slug, @year, @month = slug, year.to_i, month.to_i
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

  # breaks the general pattern to have this here rather than Sy.from_sym, but
  # the code looks nicer
  def to_sy
    Sy.new slug, year
  end

  def == other
    other.slug == slug and same_time_as? other
  end
  alias :eql :==

  def to_s
    "<Sym #{to_key}>"
  end

  def self.from_container container
    new container.slug, container.date.year, container.date.month
  end

  def self.from_message message
    new message.list.slug, message.date.year, message.date.month
  end
end
