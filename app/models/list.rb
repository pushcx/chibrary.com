class InvalidSlug < RuntimeError ; end

class List < CachedHash
  attr_reader :slug

  def initialize list
    raise InvalidSlug, "Invalid list slug '#{list}'" unless list =~ /^[a-z0-9\-]+$/ and list.length <= 20
    @slug = list
    super "list/#{list}"
  end

  def cached_message_list year, month
    begin
      $riak[month_list_key(year, month)] or []
    rescue NotFound
      []
    end
  end

  def fresh_message_list year, month
    $riak.list "list/#{@slug}/message/#{year}/#{month}"
  end

  def cache_message_list year, month, message_list
    $riak[month_list_key(year, month)] = message_list
  end

  def thread year, month, call_number
    $riak["list/#{@slug}/thread/#{year}/#{month}/#{call_number}"]
  end

  def thread_list year, month
    ThreadList.new @slug, year, month
  end

  private

  def month_list_key year, month
    "list/#{@slug}/message_list/#{year}/#{month}"
  end
end
