require 'adamantium'
require 'rmail'

# remove the existing regexp first to avoid a warning about changing it
RMail::Header::Field.send(:remove_const, :EXTRACT_FIELD_NAME_RE)
# a field name is any printable ascii character but space and :
RMail::Header::Field::EXTRACT_FIELD_NAME_RE = /\A([\x21-\x39\x3b-\x7e]+):\s*/ou

class Headers
  include Adamantium

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
