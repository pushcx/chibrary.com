require_relative 'riak_repo'
require_relative '../value/call_number'

class CallNumberListRepo
  include RiakRepo

  attr_reader :sym, :call_numbers

  def initialize sym, call_numbers
    @sym, @call_numbers  = sym, call_numbers
  end

  def extract_key
    self.class.build_key sym
  end

  def serialize
    call_numbers.map { |cn| cn.to_s }
  end

  def self.build_key sym
    sym.to_key
  end

  def self.deserialize ary
    ary.map { |str| CallNumber.new str }
  end

  def self.find sym
    key = build_key sym
    deserialize bucket[key]
  rescue NotFound
    []
  end
end
