require_relative 'call_number'

class Summary
  attr_reader :call_number, :n_subject, :date

  def initialize call_number, n_subject, date
    @call_number = CallNumber.new(call_number)
    @n_subject = n_subject
    @date = date.kind_of?(Time) ? date : Time.rfc2822(date)

    raise ArgumentError, "call_number '#{call_number}' is invalid" unless @call_number.valid?
  end

  def self.from message
    return nil if message.nil # for empty containers
    new(message.call_number, message.n_subject, message.date)
  end
end
