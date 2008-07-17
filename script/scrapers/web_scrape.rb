#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../../config/boot'

# Prototype scraper, customize for different sites.

CWD = Dir.getwd

{
#  'ruby-math' => 1026,
#  'ruby-ext'  => 2324,
#  'ruby-core' => 14083,
  'ruby-list' => 44444,
#  'ruby-dev'  => 32932,
  'ruby-talk' => 286201, #
}.each do |list, count|
  puts '*' * 80, list
  Dir.chdir "scraped/#{list}/new"
  for i in (1..count)
    fork do
      exec("wget http://blade.nagaokaut.ac.jp/ruby/#{list}/#{i} -t 5 -q -c -N --waitretry=30")
    end
    if i % 40 == 0
      puts "#{list} #{1.0 * i/count * 100}"
      Process.waitall
      sleep 1
    end
  end
  Dir.chdir CWD
end
