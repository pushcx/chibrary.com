require 'base64'
require_relative 'riak_repo'
require_relative '../value/call_number'
require_relative '../model/message'
require_relative 'email_repo'

module Chibrary

class MessageRepo
  include RiakRepo

  attr_reader :message

  def initialize message
    @message = message
  end

  def extract_key
    "#{message.call_number.to_s}"
  end

  def serialize
    {
      email:       EmailRepo.new(message.email).serialize,
      call_number: message.call_number.to_s,
      slug:        message.slug,
      source:      message.source,
      # Should this map overlay's values .to_s instead of letting .to_json do it?
      overlay:     message.overlay,
    }
  end

  def indexes
    {
      sym_bin:            message.sym.to_key,
      slug_timestamp_bin: "#{message.slug}_#{message.date.to_i}",
      id_hash_bin:        Base64.strict_encode64(message.message_id.to_s),
      author_bin:         Base64.strict_encode64(message.email.canonicalized_from_email),
    }
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize hash
    Message.new EmailRepo.deserialize(hash[:email]), hash[:call_number], hash[:slug], hash[:source], hash.fetch(:overlay, {})
  end

  def self.find call_number
    key = build_key(call_number)
    data = bucket[key]
    deserialize data
  end

  def self.find_all call_numbers
    Hash[ bucket.get_all(call_numbers).map { |k, h| [k, deserialize(h)] } ]
  end

  def self.has_message_id? message_id
    bucket.get_index('id_hash_bin', Base64.strict_encode64(message_id)).any?
  end
end

end # Chibrary
