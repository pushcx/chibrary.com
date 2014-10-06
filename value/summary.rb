require 'adamantium'

require_relative '../value/call_number'

module Chibrary

class Summary
  include Adamantium

  attr_reader :call_number, :message_id, :from, :n_subject, :date, :blurb

  def initialize call_number, message_id, from, n_subject, date, blurb
    @call_number = CallNumber.new(call_number)
    @message_id = MessageId.new(message_id)
    @from = from
    @n_subject = n_subject
    @date = date.kind_of?(Time) ? date.utc : Time.rfc2822(date).utc
    @blurb = blurb
  end

  def references ; [] ; end

  # matches API for _thread_list partial
  def no_archive?
    false
  end

  def self.from message
    return nil if message.nil? # for empty containers
    new(message.call_number, message.message_id, message.from, message.n_subject, message.date, message.blurb)
  end

  def == other
    call_number == other.call_number &&
    message_id == other.message_id &&
    from == other.from &&
    n_subject == other.n_subject &&
    date.rfc2822 == other.date.rfc2822 && # stored messages truncate microseconds
    blurb == other.blurb
  end
  alias :eql? :==
end

end # Chibrary
