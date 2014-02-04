require 'forwardable'
require_relative '../lib/string_'

class Subject
  RE_PATTERN = /\s*\[?(Re|Fwd?)([\[\(]?\d+[\]\)]?)?:\s*/i

  extend Forwardable
  def_delegators :@original, :length

  def initialize str
    @original = str || ''
  end

  def reply?
    !!(@original =~ RE_PATTERN)
  end

  def normalized
    @original.decoded.gsub(RE_PATTERN, '').strip
  end

  def to_s
    @original
  end
end

