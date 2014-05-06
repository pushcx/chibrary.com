#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'net/smtp'

def yn(str, expected)
  print str + " "
  answer = gets.chomp.downcase[0..0]
  return (answer == expected or answer.empty?)
end

list_addresses = CachedHash.new "list_address"

AWS::S3::Bucket.objects('listlibrary_archive', prefix: "_listlibrary_no_list/").each do |mail|
  message = Message.new(mail.key)
  if message.mailing_list != '_listlibrary_no_list'
    message.store
    mail.delete
    next
  end
  
  puts "\n" * 5 + mail.value

  if (
    confirmline = message.message.match(/^\s*confirm\s+.{8,}/) or
    confirmline = message.message.match(/^\s*auth\s+.{8,}/)
  ) and yn("subscribe? (Y/n):", 'y')
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
        list_addresses[address] = slug
      end
    end

    reply = <<-REPLY
From: List Library <#{MAIL_ARCHIVE}>
To: #{message.reply_to}
Subject: #{confirmline}
Date: #{Time.now.rfc822}
X-Mailing-List: listlibrary_subscriptions

#{confirmline}
    REPLY
    Net::SMTP.start(MAIL_SERVER, MAIL_SMTP_PORT, 'listlibrary.net', MAIL_USER, MAIL_PASSWORD, :login) do |smtp|
      print smtp.send_message(reply, MAIL_ARCHIVE, [(message.reply_to or message.from), 'archive@listlibrary.net'])
    end

    message.add_header("X-Mailing-List: listlibrary_subscriptions@listlibrary.net")
    message.overwrite = :do
    message.mailing_list
    message.store
    mail.delete
    next
  end

  print "Save location(slug, '_l' for subscriptions, '_d' to delete, or blank to skip): "
  case list = gets.chomp
  when '_l'
    mail.rename message.filename.split('/')[1..-1].unshift('_listlibrary_subscriptions').join('/'), mail.metadata
  when '_d'
    mail.delete
  when ''
  else
    mail.rename message.filename.split('/')[1..-1].unshift(list).join('/'), mail.metadata
  end
end
