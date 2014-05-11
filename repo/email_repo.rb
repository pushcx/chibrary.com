require_relative '../value/email'

# Does not include RiakRepo or support the same API because emails are only
# persisted in Messages.
class EmailRepo
  attr_reader :email

  def initialize email
    @email = email
  end

  def serialize
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

  def self.deserialize hash
    Email.new({
      raw:        hash[:raw],
      message_id: hash[:message_id],
      subject:    hash[:subject],
      from:       hash[:from],
      references: hash[:references],
      date:       Time.rfc2822(hash[:date]).utc,
      no_archive: hash[:no_archvie],
    })
  end
end
