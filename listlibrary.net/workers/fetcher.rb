#!/usr/bin/ruby

require 'filer'
require 'net/pop'

Net::POP3.delete_all('mail.listlibrary.net', 110, 'archive@listlibrary.net', 'y7fX$e2Z') do |message|
  next if message.length >= (256 * 1024)
  bucket, filename = Message.new(message.pop).store
  puts "#{message.number} #{bucket} #{filename}"
end
