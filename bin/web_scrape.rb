#!/usr/bin/ruby

# Prototype scraper, customize for different sites.

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
CWD = Dir.getwd

{
#  'ruby-math' => 1026,
  'ruby-ext'  => 2324,
  'ruby-core' => 14083,
  'ruby-list' => 44444,
  'ruby-dev'  => 32932,
  'ruby-talk' => 286201,
}.each do |list, count|
  puts '*' * 80, list
  Dir.chdir "scraped/#{list}/new"
  for i in (1..count)
    puts "#{list} #{1.0 * i/count * 100}" if i % 100 == 0
    `wget http://blade.nagaokaut.ac.jp/ruby/#{list}/#{i} -t 5 -q -c -N --waitretry=30`
  end
  Dir.chdir CWD
  exit
end
