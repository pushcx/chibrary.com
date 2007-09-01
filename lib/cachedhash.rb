require 'aws'

class CachedHash
  attr_reader :prefix

  @@cache = {}

  def initialize prefix
    @prefix = prefix
    @@cache[prefix] = {}
  end

  def [] key
    return @@cache[@prefix][key] if @@cache[@prefix].has_key? key

    @@cache[@prefix][key] = begin
        AWS::S3::S3Object.find("#{@prefix}/#{key}", "listlibrary_cachedhash").value.chomp
      rescue
        nil
    end
  end

  def []= key, value
    AWS::S3::S3Object.store("#{@prefix}/#{key}", (@@cache[@prefix][key] = value.to_s.chomp), "listlibrary_cachedhash", :content_type => 'text/plain')
    value
  end
end
