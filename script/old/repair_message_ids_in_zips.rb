#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

# The zipruby library was misdesigned to force all filenames to lowercase and
# lost a lot of messages. I've fixed the problem and written a test to ensure
# it doesn't recur. In rethreading I found a message whose filename was wrongly
# lowercased so I wrote this script to detect any other messages with the wrong
# key and fixed them.

# In the (ongoing) first run, it fixed that message and several dozen in the
# lkml archive that had their trailing . sheared off.

zips = `cd listlibrary_archive ; find list/ -wholename "*message*zip"`.split.sort

zips.each do |zip|
  zip = zip[0..-5] # trip off .zip
  puts zip
  $archive[zip].each do |key|
    m = $archive["#{zip}/#{key}"]
    if key != m.message_id
      puts "  #{key} #{m.message_id}"
      $archive["#{zip}/#{m.message_id}"] = m
      raise "  couldn't fix!" if $archive["#{zip}/#{m.message_id}"].message_id != m.message_id
      $archive.delete "#{zip}/#{key}"
    end
  end
end
