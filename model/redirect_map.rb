require 'forwardable'

class CircularRedirect < ArgumentError ; end

class RedirectMap
  attr_reader :sym, :redirects

  extend Forwardable
  def_delegators :@redirects, :[]

  def initialize sym, redirects={}
    @sym, @redirects = sym, redirects
  end

  def redirect call_numbers, y, m
    call_numbers.each do |call_number|
      raise CircularRedirect if sym.year == y and sym.month == m
      @redirects[call_number] = [y, m]
    end
  end

  def redirect? call_number
    @redirects[call_number]
  end
end
