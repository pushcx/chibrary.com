require 'adamantium'
require 'forwardable'

require_relative '../lib/core_ext/string_'

class Subject
  include Adamantium

  RE_PATTERN = /\s*\[?(Re|Fwd?)([\[\(]?\d+[\]\)]?)?:\s*/i

  attr_reader :original

  extend Forwardable
  def_delegators :@original, :length

  def initialize str
    @original = (str || '').to_s
  end

  def reply?
    !!(original =~ RE_PATTERN)
  end

  def normalized
    original.decoded.gsub(RE_PATTERN, '').strip
  end

  def to_s
    original
  end

  def == other
    return original == other.original if other.is_a?(Subject)
    return original == other # String
  end
end

