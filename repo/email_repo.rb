require_relative '../value/email'

# Does not include RiakRepo or support the same API because emails are only
# persisted in Messages.
class EmailRepo
  attr_reader :email

  def initialize email
    @email = email
  end

  def serialize
    email.raw
  end

  def self.deserialize str
    Email.new(str)
  end
end
