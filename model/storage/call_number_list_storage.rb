require_relative '../call_number'

class CallNumberListStorage
  include RiakStorage

  attr_reader :list, :year, :month, :call_numbers

  def initialize list, year, month, call_numbers
    @list = list
    @year = year
    @month = '%02d' % month.to_i
    @call_numbers = call_numbers
  end

  def extract_key
    "#{list.slug}/#{year}/#{month}"
  end

  def to_hash
    call_numbers.map { |cn| cn.to_s }
  end

  def self.from_hash h
    h.map { |str| CallNumber.new str }
  end

  def self.find list, year, month
    from_hash bucket["#{list.slug}/#{year}/#{month}"]
  end
end
