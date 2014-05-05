require 'rmail'

require_relative '../lib/core_ext/ice_nine_'

class Headers
  prepend IceNine::DeepFreeze

  def initialize text
    @rmail = RMail::Parser.read(text)
  end

  def [] header
    @rmail.header.fetch(header, '')
  end

  def all header
    @rmail.header.fetch_all(header)
  end
end
