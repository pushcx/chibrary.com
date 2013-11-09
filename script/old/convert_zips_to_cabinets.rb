#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

Dir['listlibrary_archive/list/*'].each do |list_path|
  puts "#{Time.now} #{list_path}"
  slug = list_path.split('/').last
  cabinet_path = "listlibrary_archive/cabinet/#{slug}.tcb"
  next if File.exists? cabinet_path

  if slug != 'linux-kernel'
  `find -L #{list_path} -name "*.zip"`.each do |zip|
    `unzip -n -d #{zip[0...zip.rindex('.')]} #{zip}`
    `rm #{zip}`
  end
  end

  cabinet = Cabinet.new cabinet_path
  archive_list_path = list_path.split('/')[1..-1].join('/')
  i = 0
  $archive[archive_list_path].each(true) do |path|
    if (i += 1) % 1000 == 0
      print '#'
      $stdout.flush
    end
    next unless File.file? "#{list_path}/#{path}"
    archive_path = "list/#{slug}/#{path}"
    cabinet[path] = $archive[archive_path]
    raise "crap - #{list_path} #{archive_path} #{cabinet_path}" if cabinet[path] != $archive[archive_path]
  end
  puts
  cabinet.close
end
puts Time.now
