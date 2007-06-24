#!/usr/bin/ruby

require 'net/pop'
require 'filer'

Net::POP3.delete_all('mail.listlibrary.net', 110, 'archive@listlibrary.net', 'y7fX$e2Z') do |message|
  continue if message.length >= (256 * 1024)
  puts Message.new(message.pop).store
end
