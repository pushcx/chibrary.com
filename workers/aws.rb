require 'rubygems'
require 'aws/s3'

require 'cachedhash'
require 'message'
require 'filer'

ACCESS_KEY_ID = '0B8FSQ35925T27X8Q4R2'
SECRET_ACCESS_KEY = 'ryM3xNKV/3OL9j5jMeJHRqSzWETxK5MeSlXj6/rv'

class AWS::S3::Bucket
  def self.keylist bucket, prefix
    last = prefix
    keys = []
    loop do
      list = begin
        get(path(bucket, { :prefix => prefix, :marker => last})).parsed['contents'].collect { |o| o['key'] }
      rescue NoMethodError
        []
      end
      break if list.empty?
      keys += list
      last = keys.last
    end
    keys
  end
end

unless defined? AWS_connection
  AWS_connection = AWS::S3::Base.establish_connection!(
    :access_key_id     => ACCESS_KEY_ID,
    :secret_access_key => SECRET_ACCESS_KEY,
    :persistent        => false
  )
end
