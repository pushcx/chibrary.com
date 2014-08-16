#!/usr/bin/env ruby
#require File.dirname(__FILE__) + '/../config/boot'
#require "#{RAILS_ROOT}/config/environment"

require 'yaml'
require 'json'
require_relative '../value/slug'
require_relative '../model/list'
require_relative '../service/filer'
require_relative '../lib/storage'

#thread_queue = Queue.new :thread

def remove_listlibrary_headers str
  # Lots of messages have Message-Id headers added;
  # Date headers were added to 3 in ruby-list, 2 in chipy
  # 3 messages in ruby-list have Date headers added
  # 2 messages in chipy have Date headers added
  while str =~ /^X-ListLibrary-Added-Header: (.*)$/
    header = $1 # Thanks, Perl
    header.sub!('\n','') # yes, remove a literal \n that yaml didn't parse
    str.sub!(/^#{header}: .*\n/, '')
    str.sub!(/^X-ListLibrary-Added-Header: .*\n/, '')
  end
  str
end

#LISTS_TO_LOAD = %w{theinfo get-theinfo process-theinfo view-theinfo mud-dev mud-dev2}
LISTS_TO_LOAD = %w{mud-dev}

filer = Chibrary::Filer.new 'riak-migration'
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
    slug = Slug.new key.split('/').first
    print "\n#{i} " if i % 1000 == 0
    if LISTS_TO_LOAD.include? slug.to_s
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
      slug = Slug.new '_no_list'
    else
      str = stored_message['message'].to_utf8 'ascii-8bit'
      source = stored_message['source']
      slug = Slug.new key.split('/').first
    end
    str = remove_listlibrary_headers(str)

    filer.file str, source, Chibrary::List.new(slug)
end
rescue Exception => e
  puts
  puts i, at
  raw = zdir.raw at
  File.write('fail', raw)
  raise e
end
filer.thread_jobs

puts Time.now
