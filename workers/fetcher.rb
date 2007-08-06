#!/usr/bin/ruby

require 'net/pop'
require 'message'
require 'aws'
require 'mail'

Net::POP3.delete_all(MAIL_SERVER, MAIL_POP3_PORT, MAIL_USER, MAIL_PASSWORD) do |mail|
  next if mail.length >= (256 * 1024)
  message = Message.new(mail.pop)
  begin
    message.store
  rescue Exception => e
    puts "#{mail.number} failed to store: #{e.message}; failure stored as #{message.generated_id}"
    AWS::S3::S3Object.store(message.generated_id, e.message + "\n" + e.backtrace.join("\n") + "\n\n" + message.message, 'listlibrary_storage_failed', :content_type => "text/plain" )
    next
  end
  puts "#{mail.number} #{message.bucket} #{message.filename}"
end