require_relative 'thread_list'

class InvalidSlug < RuntimeError ; end

class NullList
  attr_reader :slug, :name, :description, :homepage

  def initialize
    @slug = '_null_list'
    @name = 'NillList'
  end
end

class List
  attr_reader :slug, :name, :description, :homepage

  def initialize list, name=nil, description=nil, homepage=nil
    raise InvalidSlug, "Invalid list slug '#{list}'" unless list =~ /^[a-z0-9\-]+$/ and list.length <= 20
    @slug = list
    @name = name
    @description = description
    @homepage = homepage
  end

  def thread_list year, month
    ThreadList.new @slug, year, month
  end

  # all the rest of this needs to move off into MesageList and Thread
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

  private

  def month_list_key year, month
    "list/#{@slug}/message_list/#{year}/#{month}"
  end
end
