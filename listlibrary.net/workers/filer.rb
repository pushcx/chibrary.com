#!/usr/bin/ruby

require 'time'
require 'rubygems'
require 'aws/s3'
require 'aws.rb'

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
    @date = Time.rfc2822(date_line) rescue Time.parse(date_line)
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
    # TODO deal with missing message_ids
    /^Message-[Ii][dD]:\W?<?(.*)>?/.match(@headers)[1]
  end

  def filename
    sprintf("#{mailing_list}/#{year}/%02d/#{message_id}", month)
  end

  def store
    AWS::S3::S3Object.store(filename, message, 'listlibrary_storage')
    filename
  end
end
