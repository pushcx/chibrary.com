require_relative '../value/sym'

module Chibrary

class SymRepo
  attr_reader :sym

  def initialize sym
    @sym = sym
  end

  def serialize
    sym.to_key
  end

  def self.deserialize s
    Sym.new(*s.split('/'))
  end
end

end # Chibrary
