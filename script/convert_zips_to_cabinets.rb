#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

`find listlibrary_archive -name "*.zip"`.split do |zip_filename|
  zip = ZZip.new zip_filename
  cabinet = Cabinet.new zip_filename[0..-5] + '.tcb'

  # copy
  zip.each do |path|
    cabinet[path] = zip[path]
  end

  # confirm
  raise "different first keys" if zip.first != cabinet.first
  raise "different key lists"  if zip.collect != cabinet.collect
  zip.each do |path|
    raise "mismatch at path #{path}" unless zip[path] == cabinet[path]
  end

  # cleanup
  #File.unlink zip_filename
end
