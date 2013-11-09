#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

# check that every file in the new cabinet is in the old archive
Dir['listlibrary_archive/list/*'].each do |list_path|
  puts "#{Time.now} #{list_path}"
  list_path = list_path[0..-5] # strip off .tcb
  slug = list_path.split('/').last

  passed_first = %w{mud-dev view-theinfo _listlibrary_no_list chipy chiphpug process-theinfo mud-dev2 theinfo get-theinfo ruby-ext ruby-doc ruby-math}
  has_missing_messages = %w{ruby-list ruby-talk ruby-core}
  has_changed_messages = %w{ruby-dev}
  if passed_first.include? slug or has_missing_messages.include? slug or has_changed_messages.include? slug
    puts "already did #{slug}"
    next
  end

  count = 0
  $archive["list/#{slug}"].each do |path|
    cab_file = $archive["list/#{slug}/#{path}"]
    begin
      old_file = $archive["old_list/#{slug}/#{path}"]
    rescue NotFound
      puts "missing old_list/#{slug}/#{path}"
      next
    end
    puts "#{Time.now} crap (at #{count}) - #{slug}/#{path} #{cab_file.class} #{old_file.class}\n#{cab_file.to_yaml}\n#{old_file.to_yaml}" and break if cab_file != old_file
    count += 1
  end
  puts "#{count} messages checked"

end
puts "first pass done at #{Time.now}"

# check that every file in the old archive is in the new cabinet
count = 0
missing_files = []
skip_slug = nil
$archive['old_list'].each(true) do |path|
  next if path =~ /\/$/ or path =~ /\.zip$/
  path.sub!('.zip/', '/')
  slug = path.split('/').first
  next if slug == 'linux-kernel' or slug == skip_slug
  #next if missing_files.include? slug
  begin
    old_file = $archive["old_list/#{path}"]
  rescue NotFound
    old_file = "sentinel value - missing from old archive"
  end
  next if old_file.class == ZDir
  begin
    cab_file = $archive["list/#{path}"]
  rescue NotFound
    #missing_files << slug
    puts "missing list/#{path} #{old_file.class}"
    skip_slug = slug
    next
  end
  if cab_file != old_file
    puts "#{Time.now} crap (at #{count}) - #{path} #{cab_file.class} #{old_file.class}\n#{cab_file.to_yaml}\n#{old_file.to_yaml}"
    skip_slug = slug
  end
  count += 1
end
puts "#{count} messages checked"
puts "missing files from #{missing_files.to_yaml}"
puts "second pass done at #{Time.now}"
