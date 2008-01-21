#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'queue'

type = ARGV.shift.to_sym
q = Queue.new(type)
attributes = {}
while ARGV.length > 0
  attributes[ARGV.shift.to_sym] = ARGV.shift
end
q.add attributes
