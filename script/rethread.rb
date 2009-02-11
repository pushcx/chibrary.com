#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

if ARGV.empty?
  puts "call with one or more slugs"
  exit
end

@thread_q = Queue.new :thread

# build list of months to flush
ARGV.each do |slug|
  FileUtils.rm_rf "listlibrary_archive/list/#{slug}/message_list/"
  FileUtils.rm_rf "listlibrary_archive/list/#{slug}/thread/"
  FileUtils.rm_rf "listlibrary_archive/list/#{slug}/thread_list/"
  `find listlibrary_archive/list/#{slug}/message -type d -wholename '*/????/??' -o -wholename '*/????/??.zip'`.split("\n").each do |key|
    year, month = key.split('/')[-2..-1]
    month = month[0..1] # strip off any .zip
    @thread_q.add :slug => slug, :year => year, :month => month
  end
end
