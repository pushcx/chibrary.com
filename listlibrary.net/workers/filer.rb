#!/usr/bin/ruby

require 'time'
require 'rubygems'
require 'aws/s3'
require 'aws.rb'
require 'md5'

class Message
  attr_reader :message

  def initialize message
    @message = message
    @connection = AWS::S3::Base.establish_connection!(
      :access_key_id     => ACCESS_KEY_ID,
      :secret_access_key => SECRET_ACCESS_KEY
    )

    @headers = /(.*?)\n\r?\n/m.match(@message)[1]
    date_line = /^Date:\W(.*)$/.match(@headers)[1]
    @date = Time.rfc2822(date_line).utc rescue Time.parse(date_line).utc
  end

  def mailing_list
    # TODO better mailing list identification
    /^X-Mailing-List:\W(.*)/.match(@headers)[1].chomp
  end

  def year
    @date.year
  end

  def month
    @date.month
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\W?<?(.*)>?/.match(@headers)[1]
    rescue
      from = /^From:\W?.*/.match(@headers)[1]
      new_headers = "Message-Id: <#{mailing_list}-#{@date.to_i}-#{MD5.md5(from)}@generated-message-id.listlibrary.net>\nX-ListLibrary-Added: Message-Id\n"
      @headers = new_headers + @headers
      @message = new_headers + @message
      message_id
    end
  end

  def filename
    sprintf("#{mailing_list}/#{year}/%02d/#{message_id}", month)
  end

  def store
    AWS::S3::S3Object.store(filename, message, 'listlibrary_storage')
    filename
  end
end
