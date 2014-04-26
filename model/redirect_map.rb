require 'forwardable'

class CircularRedirect < ArgumentError ; end

class RedirectMap
  attr_reader :slug, :year, :month
  attr_reader :redirects

  extend Forwardable
  def_delegators :@redirects, :[]

  def initialize slug, year, month, redirects={}
    @slug, @year, @month = slug, year.to_i, month.to_i
    @redirects = redirects
  end

  def redirect call_numbers, y, m
    call_numbers.each do |call_number|
      raise CircularRedirect if year == y and month == m
      @redirects[call_number] = [y, m]
    end
  end

  def redirect? call_number
    @redirects[call_number]
  end
end
