#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

if ARGV.empty?
  puts "call with one or more slugs"
  exit
end

@publish_q = Queue.new :publish

# build list of months to flush
ARGV.each do |slug|
  next unless File.exists? "listlibrary_archive/list/#{slug}/thread"
  `find listlibrary_archive/list/#{slug}/thread -type d -wholename '*/????/??' -o -wholename '*/????/??.zip'`.split("\n").each do |key|
    year, month = key.split('/')[-2..-1]
    month = month[0..1] # strip off any .zip
    @publish_q.add :slug => slug, :year => year, :month => month
  end
end
