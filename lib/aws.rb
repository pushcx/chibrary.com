require 'rubygems'
require 'aws/s3'
require 'yaml'

require 'cachedhash'
require 'message'
require 'threading'
require 'filer'

ACCESS_KEY_ID = '0B8FSQ35925T27X8Q4R2'
SECRET_ACCESS_KEY = 'ryM3xNKV/3OL9j5jMeJHRqSzWETxK5MeSlXj6/rv'

class AWS::S3::Connection
  def self.prepare_path(path)
    path = path.remove_extended unless path.utf8?
    URI.escape(path).gsub('+', '%2B')
  end
end

class AWS::S3::Bucket
  def self.keylist bucket, prefix
    last = prefix
    keys = []
    loop do
      list = begin
        get(path(bucket, { :prefix => prefix, :marker => last})).parsed['contents'].collect { |o| o['key'].to_s }
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

class AWS::S3::S3Object
  def self.load_yaml key, bucket='listlibrary_archive'
    begin
      YAML::load(AWS::S3::S3Object.value(key, bucket))
    rescue
      nil
    end
  end
end

module Enumerable
  def sum ; inject(0) { |x, y| x + y }; end

  # Like find, but return the value of the block instead of the element.
  def argfind
    ret = nil
    find { |e| ret ||= yield(e) }
    ret || nil
  end
end

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

unless defined? AWS_connection
  AWS_connection = AWS::S3::Base.establish_connection!(
    :access_key_id     => ACCESS_KEY_ID,
    :secret_access_key => SECRET_ACCESS_KEY,
    :persistent        => false
  )
end
