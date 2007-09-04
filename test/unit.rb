#!/usr/bin/ruby

require 'test/unit'

Dir.new(File.dirname(__FILE__) + "/unit").each do |file|
  f = File.new(File.dirname(__FILE__) + "/unit/" + file, "r")
  next unless f.stat.file?
  next unless f.path.match(/\.rb$/)
  require f.path
end
