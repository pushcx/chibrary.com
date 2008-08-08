require 'storage'
require 'cachedhash'

class List < CachedHash
  attr_reader :slug

  def initialize list
    @slug = list
    super "list/#{list}"
  end

  def cached_message_list year, month
    begin
      $archive[month_list_key(year, month)] or []
    rescue NotFound
      []
    end
  end

  def fresh_message_list year, month
    $archive["list/#{@slug}/message/#{year}/#{month}"].collect.sort
  end

  def cache_message_list year, month, message_list
    $archive[month_list_key(year, month)] = message_list
  end

  def thread year, month, call_number
    $archive["list/#{@slug}/thread/#{year}/#{month}/#{call_number}"]
  end

  def thread_list year, month
    ThreadList.new @slug, year, month
  end

  private

  def month_list_key year, month
    "list/#{@slug}/message_list/#{year}/#{month}"
  end
end
