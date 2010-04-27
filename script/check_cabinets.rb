#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

Dir['listlibrary_archive/list/*'].each do |list_path|
  puts "#{Time.now} #{list_path}"
  list_path = list_path[0..-5] # strip off .tcb
  slug = list_path.split('/').last

  count = 0
  $archive["list/#{slug}"].each do |path|
    cab_file = $archive["list/#{slug}/#{path}"]
    old_file = $archive["old_list/#{slug}/#{path}"]
    raise "crap (at #{count}) - #{slug}/#{path} #{cab_file.class} #{old_file.class}\n#{cab_file.to_yaml}\n#{old_file.to_yaml}" if cab_file != old_file
    count += 1
  end
  puts "#{count} messages checked"

end
puts "first pass done at " + Time.now

count = 0
$archive['old_list'].each(true) do |path|
  cab_file = $archive["list/#{path}"]
  old_file = $archive["old_list/#{path}"]
  raise "crap (at #{count}) - #{path} #{cab_file.class} #{old_file.class}\n#{cab_file.to_yaml}\n#{old_file.to_yaml}" if cab_file != old_file
  count += 1
end
puts "#{count} messages checked"
puts "second pass done at " + Time.now
