#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'tempfile'

class CleanSnippets
  def run
    dirs = ["snippet/homepage"]
    $archive["snippet/list"].each { |slug| dirs << "snippet/list/#{slug}" }
    dirs.each do |dir|
      $archive[dir].each_with_index { |key, i| $archive[dir].delete(key) if i > 30 }
    end
  end
end

begin
  CleanSnippets.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
