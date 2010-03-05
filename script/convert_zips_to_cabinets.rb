#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

`find -L listlibrary_archive/list/ -name "*.zip"`.split.each do |zip_filename|
  puts zip_filename
  zip = ZZip.new zip_filename
  cabinet_filename = zip_filename[0..-5] + '.tcb'
  File.unlink cabinet_filename if File.exists? cabinet_filename
  cabinet = Cabinet.new cabinet_filename

  # copy
  zip.each do |path|
    cabinet[path] = zip[path]
  end

  # confirm
  raise "different first keys: zip #{zip.first} - cabinet #{cabinet.first}" if zip.first != cabinet.first
  raise "different key lists"  if zip.collect != cabinet.collect
  zip.each do |path|
    unless zip[path] == cabinet[path]
      puts zip[path].class
      puts zip[path]
      puts '-' * 80
      puts cabinet[path].class
      puts cabinet[path]
      raise "mismatch at path #{path}"
    end
  end

  # cleanup
  #File.unlink zip_filename
end
