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

start = ARGV.shift
raise "need start number" if start.nil?
start = start.to_i

#Dir['archive/old_list/*'].each do |list_path|
#  next unless list_path.include? 'theinfo' or list_path.include? 'linux-kernel'
#  puts "#{Time.now} #{list_path}"
#  slug = list_path.split('/').last
begin

  zdir = ZDir.new 'archive/old_list'
  at = nil
  raw = nil
  foo = false
  i = 0
  zdir.each(true) do |key|
    # skip dirs - why did I want that yielded in the first place?
    #next unless File.file? "#{list_path}/#{key}"
    i += 1
    foo = true if i == start #key.include? 'linux-kernel/message/2003/04/3EAC8E29.9080007@rogers.com'
    next unless foo
    print "\n#{i} " if i % 1000 == 0
    print '.'
    #puts key

    at = key
    stored_message = zdir[key]

    if stored_message.is_a? String
      str = stored_message.to_utf8 'ascii-8bit'
      source = 'riak-migration'
      slug = '_no_list'
    else
      str = stored_message['message'].to_utf8 'ascii-8bit'
      source = stored_message['source']
      slug = key.split('/').first
    end

    #call_number = CallNumberGenerator.next!
    call_number = 'x' + i.to_s.rjust(9, '0')
    message = Message.from_string(
      str,
      call_number,
      source,
      List.new(slug)
    )
    # TODO replace message id if it's @generated-message-id.listlibrary.net
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
  puts
  puts i, at
  raw = zdir.raw at
  File.write('fail', raw)
  raise e
end

puts Time.now
