#!/usr/bin/ruby

require 'time'
require 'rubygems'
require 'aws/s3'
require 'aws.rb'
require 'md5'

class Message
  attr_reader :headers, :date, :message

  @@addresses = {}

  def initialize message
    @message = message
    @connection = AWS::S3::Base.establish_connection!(
      :access_key_id     => ACCESS_KEY_ID,
      :secret_access_key => SECRET_ACCESS_KEY
    )

    @headers = /(.*?)\n\r?\n/m.match(@message)[1]
    date_line = /^Date:\s(.*)$/.match(@headers)[1].chomp
    @date = Time.rfc2822(date_line).utc rescue Time.parse(date_line).utc
    @from = /^From:\s*(.*)/.match(@headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift
  end

  def mailing_list
    matches = nil
    [/^X-Mailing-List:\s.*/, /^To:\s.*/, /^C[cC]:\s.*/].each do |regexp|
      matches = regexp.match(@headers)
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

  def year
    @date.year
  end

  def month
    @date.month
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(@headers)[1].chomp
    rescue
      new_headers = "Message-Id: <#{mailing_list}-#{@date.to_i}-#{MD5.md5(@from)}@generated-message-id.listlibrary.net>\nX-ListLibrary-Added-Header: Message-Id\n"
      @headers = new_headers + @headers
      @message = new_headers + @message
      message_id
    end
  end

  def bucket
    mailing_list ? 'listlibrary_storage' : 'listlibrary_no_mailing_list'
  end

  def filename
    ( mailing_list ? "#{mailing_list}/" : "" ) + sprintf("#{year}/%02d/#{message_id}", month)
  end

  def store
    AWS::S3::S3Object.store(filename, message, bucket)
    [bucket, filename]
  end
end
