require 'adamantium'

require_relative '../value/call_number'

class Summary
  include Adamantium

  attr_reader :call_number, :from, :n_subject, :date, :blurb

  def initialize call_number, from, n_subject, date, body
    @call_number = CallNumber.new(call_number)
    @from = from
    @n_subject = n_subject
    @date = date.kind_of?(Time) ? date : Time.rfc2822(date).utc
    @blurb = body.split("\n").select { |l| not (l.chomp.empty? or l =~ /^>|@|:$/) }[0..4].join("\n")
  end

  # matches API for _thread_list partial
  def no_archive?
    false
  end

  def self.from message
    return nil if message.nil? # for empty containers
    new(message.call_number, message.from, message.n_subject, message.date, message.body)
  end
end
