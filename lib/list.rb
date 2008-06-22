require 'storage'
require 'cachedhash'
require 'stdlib'

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
    $archive["list/#{@slug}/message/#{year}/#{month}/"].collect(true).sort
  end

  def cache_message_list year, month, message_list
    $archive[month_list_key(year, month)] = message_list
  end

  def thread year, month, call_number
    $archive["list/#{@slug}/thread/#{year}/#{month}/#{call_number}"]
  end

  def thread_list year, month
    $archive[thread_list_key(year, month)]
  end

  def year_counts
    years = {}
    $cachedhash["list/#{@slug}/thread_list/"].each do |key|
      thread_list = $archive[key]
      year, month = key.split('/')[3..4]
      years[year] ||= {}
      years[year][month] = { :threads => render_month.length, :messages => render_month.collect { |t| t[:messages] }.sum }
    end
    return years
  end

  def cache_thread_list year, month, thread_list
    $archive[thread_list_key(year, month)] = thread_list
  end

  private

  def month_list_key year, month
    "list/#{@slug}/message_list/#{year}/#{month}"
  end

  def thread_list_key year, month
    "list/#{@slug}/thread_list/#{year}/#{month}"
  end
end
