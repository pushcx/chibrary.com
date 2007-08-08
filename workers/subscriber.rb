#!/usr/bin/ruby

require 'net/smtp'
require 'time'
require 'message'
require 'aws'
require 'mail'

def yn(str, expected)
  print str + " "
  answer = gets.chomp.downcase[0..0]
  return (answer == expected or answer.empty?)
end

mailing_list_addresses = CachedHash.new "mailing_list_addresses"

AWS::S3::Bucket.objects('listlibrary_archive', :prefix => "_listlibrary_no_list/").each do |mail|
  message = Message.new(mail.key)
  if message.mailing_list != '_listlibrary_no_list'
    message.store
    mail.delete
    next
  end
  
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
        mailing_list_addresses[address] = slug
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

  print "Save location(slug, '_d', or blank to skip): "
  case list = gets.chomp
  when '_d'
    mail.delete
  when ''
  else
    mail.rename message.filename.split('/')[1..-1].unshift(list).join('/')
  end
end
