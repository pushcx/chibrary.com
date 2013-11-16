#!/usr/bin/ruby

# Scrapes the ruby lists from blade.nagaokaut.ac.jp

CWD = Dir.getwd

{ # the current max message number found by browsing the pages
  'ruby-math' => 1026,
  'ruby-ext'  => 2330,
  'ruby-core' => 17492,
  'ruby-list' => 45177,
  'ruby-dev'  => 35305,
  'ruby-talk' => 306950,
}.each do |list, count|
  puts '*' * 80, list
  Dir.chdir "scraped/#{list}/new"
  for i in (0..count)
    break if i >= 45000
    i = count - i
    puts "#{list} #{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{i} messages, #{1.0 * i/count * 100}%" if i % 300 == 0
    `wget http://blade.nagaokaut.ac.jp/ruby/#{list}/#{i} -q -c -N --waitretry=5`
  end
  Dir.chdir CWD
end
