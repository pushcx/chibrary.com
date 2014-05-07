#!/usr/bin/env ruby
#require File.dirname(__FILE__) + '/../config/boot'
#require "#{RAILS_ROOT}/config/environment"

require 'yaml'
require 'json'
require_relative '../lib/storage.rb'
require_relative '../service/call_number_service.rb'
require_relative '../model/list.rb'
require_relative '../model/message.rb'
require_relative '../repo/message_repo.rb'

#thread_queue = Queue.new :thread

def remove_listlibrary_headers str
  # Lots of messages have Message-Id headers added;
  # Date headers were added to 3 in ruby-list, 2 in chipy
  # 3 messages in ruby-list have Date headers added
  # 2 messages in chipy have Date headers added
  while str =~ /^  X-ListLibrary-Added-Header: (.*)$/
    header = $1 # Thanks, Perl
    header.sub!('\n','') # yes, remove a literal \n that yaml didn't parse
    str.sub!(/^  #{header}: .*\n/, '')
    str.sub!(/^  X-ListLibrary-Added-Header: .*\n/, '')
  end
  str
end

LISTS_TO_LOAD = %w{theinfo get-theinfo process-theinfo view-theinfo mud-dev mud-dev2}

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
    foo = true if i >= start #key.include? 'linux-kernel/message/2003/04/3EAC8E29.9080007@rogers.com'
    next unless foo
    slug = key.split('/').first
    print "\n#{i} " if i % 1000 == 0
    if LISTS_TO_LOAD.include? slug
      print 'x'
    else
      print '.'
      next
    end
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
    str = remove_listlibrary_headers(str)

    #call_number = CallNumberService.next!
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
    ms = MessageRepo.new(message, MessageRepo::Overwrite::DO)
    ms.extract_key
    ms.serialize
    Base64.strict_encode64(message.message_id.to_s)
    "#{message.list.slug}/#{message.date.year}/%02d" % message.date.month
    Base64.strict_encode64(message.email.canonicalized_from_email)
    #MessageRepo.new(message, MessageRepo::Overwrite::DO).store

    # queue threader for this list
#    thread_queue.add :slug => slug, :year => message.date.year, :month => "%02d" % message.date.month
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
