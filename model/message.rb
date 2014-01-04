require 'forwardable'

require_relative 'call_number'
require_relative 'email'

class Message
  attr_accessor :email, :call_number, :source, :list
  attr_reader :message_id

  extend Forwardable
  def_delegators :@email, :n_subject, :date

  def initialize email, call_number, source=nil, list=nil
    @email = email
    @call_number = CallNumber.new(call_number)
    @source = source
    @list = list

    raise ArgumentError, "call_number '#{call_number}' is invalid" unless @call_number.valid?
    @message_id = MessageId.extract_or_generate(email.message_id, call_number)
  end

  def self.from_string str, call_number, source=nil, list=nil
    Message.new Email.new(raw: str), call_number, source, list
  end

  def self.from_message m
    Message.new m.email, m.call_number, m.source, m.list
  end

  def == o
    o.email == email and o.source == source and o.call_number == call_number and o.message_id == message_id
  end
end
