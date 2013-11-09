#!/usr/bin/env ruby
#require File.dirname(__FILE__) + '/../config/boot'
#require "#{RAILS_ROOT}/config/environment"

require 'json'
require_relative '../lib/storage.rb'
require_relative '../app/models/message.rb'
require_relative '../app/models/queue.rb'
require_relative '../app/models/cached_hash.rb'

thread_queue = Queue.new :thread

Dir['archive/old_list/*'].each do |list_path|
  next unless list_path.include? 'theinfo'
  puts "#{Time.now} #{list_path}"
  slug = list_path.split('/').last

  # copy all messages in
  zdir = ZDir.new list_path
  zdir.each(true) do |key|
    # skip dirs - why did I want that yielded in the first place?
    next unless File.file? "#{list_path}/#{key}"
    puts key
    message = zdir[key]
    $riak["#{slug}/#{key}"] = message.to_hash

    # queue threader for this list
    thread_queue.add :slug =>slug, :year => message.date.year, :month => "%02d" % message.date.month
  end


#  cabinet = Cabinet.new cabinet_path
#  archive_list_path = list_path.split('/')[1..-1].join('/')
#  i = 0
#  $archive[archive_list_path].each(true) do |path|
#    if (i += 1) % 1000 == 0
#      print '#'
#      $stdout.flush
#    end
#    next unless File.file? "#{list_path}/#{path}"
#    archive_path = "list/#{slug}/#{path}"
#    cabinet[path] = $archive[archive_path]
#    raise "crap - #{list_path} #{archive_path} #{cabinet_path}" if cabinet[path] != $archive[archive_path]
#  end
#  puts
#  cabinet.close
end


puts Time.now
