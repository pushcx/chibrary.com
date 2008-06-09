require 'storage'

class CachedHash
  attr_reader :prefix

  @@cache = {}

  def initialize prefix
    @prefix = prefix
    @@cache[prefix] ||= {}
  end

  def [] key
    return @@cache[@prefix][key] if @@cache[@prefix].has_key? key

    @@cache[@prefix][key] = begin
      $storage.load_string("listlibrary_cachedhash", "#{@prefix}/#{key}").chomp
    rescue NotFound
      nil
    end
  end

  def []= key, value
    $storage.store_string("listlibrary_cachedhash", "#{@prefix}/#{key}", (@@cache[@prefix][key] = value.to_s.chomp))
    value
  end
end
