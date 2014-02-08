require 'base64'
require_relative '../call_number'
require_relative '../message'

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
    "/#{message.call_number}"
  end

  def to_hash
    {
      source:      message.source,
      call_number: message.call_number.to_s,
      message_id:  message.message_id,
      list_slug:   message.list.slug,
      email:       EmailStorage.new(message.email).to_hash,
    }
  end

  def dont_overwrite_if_already_stored key
    if overwrite == Overwrite::DONT
      return bucket.has_key? key
    end
    false
  end

  def guard_against_error_overwrite key
    if overwrite == Overwrite::ERROR
      exists = bucket.has_key? key
      raise MessageOverwriteError, "overwrite attempted for chibrary_archive #{@key}" if exists
    end
  end

  def store
    key = extract_key
    guard_against_error_overwrite(key)
    return message if dont_overwrite_if_already_stored(key)

    obj = bucket.new
    obj.key = key
    obj.data = to_hash
    obj.indexes['id_hash_bin']   << Base64.strict_encode64(message.message_id)
    obj.indexes['lmy_bin']       << "#{message.list.slug}/#{message.date.year}/%02d" % message.date.month
    obj.indexes['from_hash_bin'] << Base64.strict_encode64(message.email.canonicalized_from_email)
    obj.store

    message
  end

  def self.build_key call_number
    "/#{call_number}"
  end

  def self.from_hash hash
    Message.new EmailStorage.from_hash(hash[:email]), hash[:call_number], hash[:source], List.new(hash[:list_slug])
  end

  def self.find call_number
    from_hash(bucket[build_key(call_number)])
  end

  def self.call_number_list list, year, month
    bucket.get_index('lmy_bin', "#{list.slug}/#{year}/%02d" % month).map { |k| CallNumber.new k }
  end
end
