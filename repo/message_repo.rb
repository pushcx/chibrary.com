require 'base64'
require_relative 'riak_repo'
require_relative '../value/call_number'
require_relative '../model/message'
require_relative 'email_repo'

module Chibrary

class MessageRepo
  include RiakRepo

  attr_reader :message, :sym

  def initialize message, sym
    @message = message
    @sym = sym
  end

  def extract_key
    "#{message.call_number.to_s}"
  end

  def serialize
    {
      email:       EmailRepo.new(message.email).serialize,
      call_number: message.call_number.to_s,
      source:      message.source,
      # Should this map overlay's values .to_s instead of letting .to_json do it?
      overlay:     message.overlay,
    }
  end

  def indexes
    ix = {}
    ix[:id_hash_bin] = Base64.strict_encode64(message.message_id.to_s)
    ix[:sym_bin] = sym.to_key
    ix[:slug_timestamp_bin] = "#{sym.slug}_#{message.date.to_i}"
    ix[:author_bin] = Base64.strict_encode64(message.email.canonicalized_from_email)
    ix
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize hash
    Message.new EmailRepo.deserialize(hash[:email]), hash[:call_number], hash[:source], hash.fetch(:overlay, {})
  end

  def self.find call_number
    deserialize(bucket[build_key(call_number)])
  end

  def self.find_all call_numbers
    bucket.get_many(call_numbers).map { |k, h| deserialize h }
  end

  def self.has_message_id? message_id
    bucket.get_index('id_hash_bin', Base64.strict_encode64(message_id)).any?
  end
end

end # Chibrary
