require 'base64'
require_relative 'riak_repo'
require_relative '../value/call_number'
require_relative '../model/message'
require_relative 'email_repo'

class MessageOverwriteError < StandardError ; end

class MessageRepo
  include RiakRepo

  attr_reader :message, :sym, :overwrite

  module Overwrite
    ERROR = :error
    DO = :do
    DONT = :dont
  end

  def initialize message, sym, overwrite=Overwrite::ERROR
    @message = message
    @sym = sym
    @overwrite = overwrite
  end

  def extract_key
    "#{message.call_number.to_s}"
  end

  def serialize
    {
      email:       EmailRepo.new(message.email).serialize,
      call_number: message.call_number.to_s,
      source:      message.source,
      overlay:     message.overlay,
    }
  end

  def dont_overwrite_if_already_stored key
    if overwrite == Overwrite::DONT
      return bucket.exists? key
    end
    false
  end

  def guard_against_error_overwrite key
    if overwrite == Overwrite::ERROR
      exists = bucket.exists? key
      raise MessageOverwriteError, "overwrite attempted for Message #{@key}" if exists
    end
  end

  def store
    key = extract_key
    guard_against_error_overwrite(key)
    return message if dont_overwrite_if_already_stored(key)

    obj = bucket.new
    obj.key = key
    obj.data = serialize
    obj.indexes['id_hash_bin'] << Base64.strict_encode64(message.message_id.to_s) if message.message_id.valid?
    obj.indexes['sym_bin']     << sym.to_key
    obj.indexes['author_bin']  << Base64.strict_encode64(message.email.canonicalized_from_email)
    obj.store

    message
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
end
