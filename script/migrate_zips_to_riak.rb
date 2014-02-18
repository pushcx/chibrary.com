#!/usr/bin/env ruby
#require File.dirname(__FILE__) + '/../config/boot'
#require "#{RAILS_ROOT}/config/environment"

require 'yaml'
require 'json'
require_relative '../lib/storage.rb'
require_relative '../model/call_number_generator.rb'
require_relative '../model/list.rb'
require_relative '../model/message.rb'
require_relative '../model/storage/message_storage.rb'

#thread_queue = Queue.new :thread

#Dir['archive/old_list/*'].each do |list_path|
#  next unless list_path.include? 'theinfo' or list_path.include? 'linux-kernel'
#  puts "#{Time.now} #{list_path}"
#  slug = list_path.split('/').last
begin

  zdir = ZDir.new 'archive/old_list'
  at = nil
  raw = nil
  foo = false
  zdir.each(true) do |key|
    # skip dirs - why did I want that yielded in the first place?
    #next unless File.file? "#{list_path}/#{key}"
    foo = true if key.include? 'linux-kernel/'
    next unless foo
    puts key

    at = key
    raw = zdir.raw key
    stored_message = zdir[key]

    if stored_message.is_a? String
      str = stored_message.to_utf8 'ascii-8bit'
      source = 'riak-migration'
      slug = '_no_list'
    else
      str = stored_message['message'].to_utf8 'ascii-8bit'
      source = stored_message['source']
      slug = stored_message['slug']
    end

    call_number = CallNumberGenerator.next!
    message = Message.from_string(
      str,
      call_number,
      source,
      List.new(slug)
    )
    # TODO replace message id if it's listlibrary
    # TODO remove any listlibrary added headers - there's some in chipy

    # just exercising the message rather than actually storing it
    ms = MessageStorage.new(message, MessageStorage::Overwrite::DO)
    ms.extract_key
    ms.serialize
    Base64.strict_encode64(message.message_id.to_s)
    "#{message.list.slug}/#{message.date.year}/%02d" % message.date.month
    Base64.strict_encode64(message.email.canonicalized_from_email)
    #MessageStorage.new(message, MessageStorage::Overwrite::DO).store

    # queue threader for this list
#    thread_queue.add :slug =>slug, :year => message.date.year, :month => "%02d" % message.date.month
#  end

end
rescue Exception => e
  puts at
  File.write('fail', raw)
  raise e
end

puts Time.now
