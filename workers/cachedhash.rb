require 'aws'

class CachedHash
  attr_reader   :prefix
  attr_accessor :S3Object

  @@cache = {}

  def initialize prefix
    @S3Object = AWS::S3::S3Object
    @prefix = prefix
    @@cache[prefix] = {}
  end

  def [] key
    return @@cache[@prefix][key] if @@cache[@prefix].has_key? key

    @@cache[@prefix][key] = begin
        @S3Object.find("#{@prefix}/#{key}", "listlibrary_cachedhash").value.chomp
      rescue AWS::S3::NoSuchKey
        nil
    end
  end

  def []= key, value
    @S3Object.store("#{@prefix}/#{key}", (@@cache[@prefix][key] = value.to_s.chomp), "listlibrary_cachedhash", :content_type => 'text/plain')
    value
  end
end
