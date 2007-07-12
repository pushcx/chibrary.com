#!/usr/bin/ruby

require 'time'
require 'md5'
require 'aws'

class Message
  attr_reader   :headers, :message
  attr_reader   :from, :date, :subject, :in_reply_to, :reply_to
  attr_accessor :overwrite, :S3Object

  @@addresses = {}

  def initialize message
    @S3Object = AWS::S3::S3Object

    if message.match "\n" # initialized with a message
      @message = message
    else                  # initialize with a url
      @message = @S3Object.find(message, 'listlibrary_storage').value
    end
    populate_headers
  end

  def populate_headers
    @headers     = /(.*?)\n\r?\n/m.match(message)[1]

    date_line    = /^Date:\s(.*)$/.match(headers)[1].chomp
    @date        = Time.rfc2822(date_line).utc rescue Time.parse(date_line).utc

    @subject     = /^Subject:\s*(.*)/.match(headers).captures.shift
    @from        = /^From:\s*(.*)/.match(headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift
    @reply_to    = /^Reply-[Tt]o:\s*(.*)/.match(headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift if headers.match(/^Reply-[Tt]o/)

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
    [/^X-Mailing-List:\s.*/, /^To:\s.*/, /^C[cC]:\s.*/, /^Reply-[Tt]o:\s.*/].each do |regexp|
      matches = regexp.match(headers)
      break unless matches.nil?
    end
    return nil if matches.nil?

    slug = nil
    matches[0].chomp.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.each do |address|
      slug = address_to_slug address
      break unless slug.nil?
    end

    slug
  end

  def address_to_slug address
    return @@addresses[address] if @@addresses.has_key? address

    @@addresses[address] = begin
        @S3Object.find(address, 'listlibrary_mailing_lists').value.chomp
      rescue AWS::S3::NoSuchKey
        nil
      end
  end

  def generated_id
    "#{mailing_list}-#{date.to_i}-#{MD5.md5(from)}@generated-message-id.listlibrary.net"
  end

  def add_header(header)
    name = header.match(/^(.+?):\s/).captures.shift
    new_headers = "#{header.chomp}\n"
    new_headers += "X-ListLibrary-Added-Header: #{name}\n" unless name.match(/^X-ListLibrary-/)
    @headers = new_headers + headers
    @message = new_headers + message
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(headers)[1].chomp
    rescue
      add_header "Message-Id: <#{generated_id}>"
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
    unless @overwrite
      raise "overwrite attempted for #{bucket} #{filename}" if @S3Object.exists?(filename, bucket)
    end
    @S3Object.store(filename, message, bucket, {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => from,
      :'x-amz-meta-subject'     => subject,
      :'x-amz-meta-in_reply_to' => in_reply_to,
      :'x-amz-meta-date'        => date
    })
    self
  end
end
