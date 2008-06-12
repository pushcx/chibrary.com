require 'rubygems'
require 'aws/s3'
require 'yaml'

class NotFound < RuntimeError ; end


class AWS::S3::Connection
  def self.prepare_path(path)
    path = path.remove_extended unless path.utf8?
    URI.escape(path).gsub('+', '%2B')
  end
end

class AWS::S3::Bucket
  def self.keylist bucket, prefix, last=nil
    last = prefix if last.nil?
    loop do
      keys = begin
        get(path(bucket, { :prefix => prefix, :marker => last})).parsed['contents'].collect { |o| o['key'].to_s }
      rescue NoMethodError
        []
      end
      break if keys.empty?
      keys.each do |k|
        begin
          yield k
        rescue Errno::ECONNRESET
          sleep 2
          yield k
        end
      end
      last = keys.last
    end
  end
end


class S3Storage
  ACCESS_KEY_ID = '0B8FSQ35925T27X8Q4R2'
  SECRET_ACCESS_KEY = 'ryM3xNKV/3OL9j5jMeJHRqSzWETxK5MeSlXj6/rv'

  def list_keys(bucket, prefix)
    AWS::S3::Bucket.keylist(bucket, prefix)
  end

  def exists?(bucket, key)
    AWS::S3::S3Object.exists? key, bucket
  end

  def size(bucket, key)
    begin
      AWS::S3::S3Object.find(key, 'listlibrary_archive').about['content-length']
    rescue AWS::S3::NoSuchKey ; raise NotFound ; end
  end

  def delete(bucket, key)
    AWS::S3::S3Object.delete(key, bucket)
  end

  def load_string(bucket, key)
    AWS::S3::S3Object.value(key, bucket)
  end

  def load_yaml(bucket, key)
    begin
      YAML::load(load_string(bucket, key))
    rescue AWS::S3::NoSuchKey
      nil
    end
  end

  def store_string(bucket, key, str)
    AWS::S3::S3Object.store(key, str.to_s.chomp, bucket, :content_type => 'text/plain')
  end

  def store_yaml(bucket, key, obj)
    store_string(bucket, key, obj.to_yaml)
  end
end

class FileStorage
  def list_keys(bucket, prefix)
    Dir.entries(filename(bucket, prefix))[2..-1].each { |k| yield k }
  end

  def exists?(bucket, key)
    File.exists? filename(bucket, key)
  end

  def size(bucket, key)
    begin
      File.size(filename(bucket, key))
    rescue Errno::ENOENT ; raise NotFound ; end
  end

  def delete(bucket, key)
    begin
      File.delete(filename(bucket, key))
    rescue Errno::ENOENT ; end # ignore exception to act idempotently
  end

  def load_string(bucket, key)
    begin
      File.read(filename(bucket, key))
    rescue Errno::ENOENT ; raise NotFound ; end
  end

  def load_yaml(bucket, key)
    YAML::load(load_string(bucket, key))
  end

  def store_string(bucket, key, str)
    f = filename(bucket, key)
    `mkdir -p #{f.split('/')[0..-2].join('/')}`
    File.open(f, 'w') do |f|
      f.write(str.to_s.chomp)
    end
  end
  
  def store_yaml(bucket, key, obj)
    store_string(bucket, key, obj.to_yaml)
  end

  private

  def filename(bucket, key)
    "#{bucket}/#{key}"
  end
end

$storage ||= FileStorage.new

if $storage.is_a? S3Storage
  unless defined? AWS_connection
    AWS_connection = AWS::S3::Base.establish_connection!(
      :access_key_id     => ACCESS_KEY_ID,
      :secret_access_key => SECRET_ACCESS_KEY,
      :persistent        => false
    )
  end
end
