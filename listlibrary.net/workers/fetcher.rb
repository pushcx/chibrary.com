#!/usr/bin/ruby

require 'rubygems'
require 'net/pop'

require 'sqs'
require 'aws.rb'
SQS.access_key_id = ACCESS_KEY_ID
SQS.secret_access_key = SECRET_ACCESS_KEY
filing = SQS.get_queue 'listlibrary_filing'

Net::POP3.delete_all('mail.listlibrary.net', 110, 'archive@listlibrary.net', 'y7fX$e2Z') do |message|
  continue if message.length >= 256 * 1024
  filing.send_message message.pop
end
