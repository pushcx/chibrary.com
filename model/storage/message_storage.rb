require 'base64'
require_relative 'riak_storage'
require_relative '../call_number'
require_relative '../message'
require_relative 'email_storage'

class MessageOverwriteError < StandardError ; end

class MessageStorage
  include RiakStorage

  attr_reader :message, :overwrite

  module Overwrite
    ERROR = :error
    DO = :do
    DONT = :dont
  end

  def initialize message, overwrite=Overwrite::ERROR
    @message = message
    @overwrite = overwrite
  end

  def extract_key
    "#{message.call_number.to_s}"
  end

  def serialize
    {
      source:      message.source,
      call_number: message.call_number.to_s,
      message_id:  message.message_id,
      list_slug:   message.list.slug,
      email:       EmailStorage.new(message.email).serialize,
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
      raise MessageOverwriteError, "overwrite attempted for chibrary_archive #{@key}" if exists
    end
  end

  def store
    key = extract_key
    guard_against_error_overwrite(key)
    return message if dont_overwrite_if_already_stored(key)

    obj = bucket.new
    obj.key = key
    obj.data = serialize
    obj.indexes['id_hash_bin'] << Base64.strict_encode64(message.message_id.to_s)
    obj.indexes['sym_bin']     << Sym.from_message(message).to_key
    obj.indexes['author_bin']  << Base64.strict_encode64(message.email.canonicalized_from_email)
    obj.store

    message
  end

  def self.build_key call_number
    call_number.to_s
  end

  def self.deserialize hash
    Message.new EmailStorage.deserialize(hash[:email]), hash[:call_number], hash[:source], List.new(hash[:list_slug])
  end

  def self.find call_number
    deserialize(bucket[build_key(call_number)])
  end

  def self.call_number_list sym
    bucket.get_index('sym_bin', sym.to_key).map { |k| CallNumber.new k }
  end
end
