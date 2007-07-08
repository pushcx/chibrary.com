#!/usr/bin/ruby

require 'net/smtp'
require 'time'
require 'filer'
require 'aws'
require 'mail'

def yn(str, expected)
  print str + " "
  answer = gets.chomp.downcase[0..0]
  return (answer == expected or answer.empty?)
end

no_mailing_list = AWS::S3::Bucket.find('listlibrary_no_mailing_list')

no_mailing_list.objects(true).each do |mail|
  next if mail.key.match '2007/06' # hack workaround for http://developer.amazonwebservices.com/connect/thread.jspa?threadID=15956

  message = Message.new(mail.value)
  
  puts "\n" * 5 + mail.value

  if confirmline = message.message.match(/^confirm\s+.{8,}/) and yn("subscribe? (Y/n):", 'y')
    print "slug? "
    slug = gets.chomp

    unless slug.empty? # in case I've done this and something blew up
      addresses = []
      while true
        print "address? "
        a = gets.chomp
        break if a.empty?
        addresses.push a
      end

      addresses.each do |address|
        AWS::S3::S3Object.store(address, slug, "listlibrary_mailing_lists", :content_type => 'text/plain')
      end
    end

    print confirmline
    reply = Message.new <<-REPLY
From: List Library <#{MAIL_ARCHIVE}>
To: #{message.reply_to}
Subject: #{confirmline}
Date: #{Time.now.rfc822}
X-Mailing-List: listlibrary_subscriptions

#{confirmline}
    REPLY
    reply.message_id # force one to be generated
    Net::SMTP.start(MAIL_SERVER, MAIL_SMTP_PORT, 'listlibrary.net', MAIL_USER, MAIL_PASSWORD, :login) do |smtp|
      print smtp.send_message(reply.message, MAIL_ARCHIVE, [message.reply_to])
    end
    reply.store

    message.add_header("X-Mailing-List: listlibrary_subscriptions@listlibrary.net")
    message.overwrite = true
    message.mailing_list
    message.store
    mail.delete
    next
  end

  if yn("delete? (Y/n):", 'y')
    mail.delete
  end
end
