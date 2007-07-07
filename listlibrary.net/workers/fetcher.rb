#!/usr/bin/ruby

require 'filer'
require 'net/pop'
require 'aws.rb'

Net::POP3.delete_all('mail.listlibrary.net', 110, 'archive@listlibrary.net', 'y7fX$e2Z') do |mail|
  next if mail.length >= (256 * 1024)
  message = Message.new(mail.pop)
  begin
    message.store
  rescue Exception => e
    puts "#{mail.number} failed to store"
    AWS::S3::S3Object.store(message.generated_id, e.message + "\n" + e.backtrace + "\n\n" + message.message, 'listlibrary_storage_failed')
    next
  end
  puts "#{mail.number} #{message.bucket} #{message.filename}"
end
