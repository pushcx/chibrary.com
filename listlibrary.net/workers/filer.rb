#!/usr/bin/ruby

require 'time'
require 'aws.rb'
require 'md5'

class Message
  attr_reader :headers, :message
  attr_reader :from, :date, :subject, :in_reply_to

  @@addresses = {}

  def initialize message
    if message.match "\n" # initialized with a message
      @message = message
    else                  # initialize with a url
      @message = AWS::S3::S3Object.find(message, 'listlibrary_storage').value
    end
    populate_headers
  end

  def populate_headers
    @headers     = /(.*?)\n\r?\n/m.match(message)[1]

    date_line    = /^Date:\s(.*)$/.match(headers)[1].chomp
    @date        = Time.rfc2822(date_line).utc rescue Time.parse(date_line).utc

    @subject     = /^Subject:\s*(.*)/.match(headers).captures.shift
    @from        = /^From:\s*(.*)/.match(headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift

    begin
      @in_reply_to = /^In-[Rr]eply-[Tt]o:\s*<?(.*)>?/.match(headers).captures.shift
    rescue
      @in_reply_to = nil
      # assume last reference is the parent and use it
      if references = /^References:\s*(.*)/.match(headers)
        @in_reply_to = references.captures.shift.split(/\s+/).last.match(/<?([^>]+)>?/).captures.shift
      end
    end
  end

  def mailing_list
    matches = nil
    [/^X-Mailing-List:\s.*/, /^To:\s.*/, /^C[cC]:\s.*/].each do |regexp|
      matches = regexp.match(headers)
      break unless matches.nil?
    end
    return nil if matches.nil?

    slug = nil
    matches[0].chomp.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.each do |address|
      slug = address_to_slug address
      break unless slug.nil?
    end

    return nil if slug.nil?
    slug
  end

  def address_to_slug address
    return @@addresses[address] if @@addresses.has_key? address

    @@addresses[address] = begin
        AWS::S3::S3Object.find(address, 'listlibrary_mailing_lists').value
      rescue AWS::S3::NoSuchKey
        nil
      end
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(headers)[1].chomp
    rescue
      new_headers = "Message-Id: <#{mailing_list}-#{date.to_i}-#{MD5.md5(from)}@generated-message-id.listlibrary.net>\nX-ListLibrary-Added-Header: Message-Id\n"
      @headers = new_headers + headers
      @message = new_headers + message
      message_id
    end
  end

  def bucket
    mailing_list ? 'listlibrary_storage' : 'listlibrary_no_mailing_list'
  end

  def filename
    ( mailing_list ? "#{mailing_list}/" : "" ) + sprintf("#{date.year}/%02d/", date.month) + message_id
  end

  def store
    AWS::S3::S3Object.store(filename, message, bucket, {
      :'x-amz-meta-from'        => from,
      :'x-amz-meta-subject'     => subject,
      :'x-amz-meta-in_reply_to' => in_reply_to,
      :'x-amz-meta-date'        => date
    })
    [bucket, filename]
  end
end
