# mud-dev zip -> maildir. Archive available at:
# http://www.raphkoster.com/2007/02/02/full-mud-dev-archive-for-download/
# http://mkhh.net/MUD-Archive.zip
# http://www.mydreamrpg.com/community/showthread.php?p=8046
# http://muddev.wishes.net
#
# There's an archive labeled mud-dev that doesn't match up with this at:
# http://marc.info/?l=mud-dev 
require 'rubygems'
require 'htmlentities'

coder = HTMLEntities.new

Dir.entries('mud-dev/html/').each do |f|
  puts f
  next if f !~ /\.html$/
  str = File.read("mud-dev/html/#{f}")
  from = coder.decode(str.match(/<B>From: <A href="mailto:.*?">(.*?)<\/A>/i).captures[0])
  date = coder.decode(str.match(/<B>Date:<\/B> (.*?)<BR>/i).captures[0])
  subject = coder.decode(str.match(/<H2>\d+: (.*?)<\/H2>/i).captures[0])
  body = coder.decode(str.match(/<PRE>(.*?)<\/PRE>/im).captures[0].gsub(/<(.*?)>/, ''))

  File.open("mud-dev/new/#{f[0..-6]}", "w") do |file|
    file.write("""From: #{from}
Date: #{date}
Subject: #{subject}

#{body}
""".chomp)
  end
end
