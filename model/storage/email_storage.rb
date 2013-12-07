require_relative '../email'

# Does not include RiakStorage or support the same API because emails are only
# persisted in Messages.
class EmailStorage
  attr_reader :email

  def initialize email
    @email = email
  end

  def to_hash
    {
      raw:        email.raw,
      # These specific fields are archived because they may be edited by code
      # or by hand to correct invalid data in raw messages.
      message_id: email.message_id.to_s,
      subject:    email.subject.to_s,
      from:       email.from,
      references: email.references,
      date:       email.date.rfc2822,
      no_archive: email.no_archive,
      # may want to add body here as well, depending on encoding woes
    }
  end

  def self.from_hash hash
    Email.new hash
  end
end
