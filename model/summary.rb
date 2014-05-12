require_relative '../value/call_number'

class Summary
  attr_reader :call_number, :n_subject, :date, :blurb

  def initialize call_number, n_subject, date, body
    @call_number = CallNumber.new(call_number)
    @n_subject = n_subject
    @date = date.kind_of?(Time) ? date : Time.rfc2822(date).utc
    @blurb = body.split("\n").select { |l| not (l.chomp.empty? or l =~ /^>|@|:$/) }[0..4].join("\n")
  end

  def self.from message
    return nil if message.nil? # for empty containers
    new(message.call_number, message.n_subject, message.date, message.body)
  end
end
