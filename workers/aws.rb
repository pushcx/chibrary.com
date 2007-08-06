require 'rubygems'
require 'aws/s3'
require 'cachedhash'

ACCESS_KEY_ID = '0B8FSQ35925T27X8Q4R2'
SECRET_ACCESS_KEY = 'ryM3xNKV/3OL9j5jMeJHRqSzWETxK5MeSlXj6/rv'

unless defined? AWS_connection
  AWS_connection = AWS::S3::Base.establish_connection!(
    :access_key_id     => ACCESS_KEY_ID,
    :secret_access_key => SECRET_ACCESS_KEY,
    :persistent        => false
  )
end
