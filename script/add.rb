#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

type = ARGV.shift.to_sym
q = Queue.new(type)
attributes = {}
while ARGV.length > 0
  attributes[ARGV.shift.to_sym] = ARGV.shift
end
q.add attributes
