require 'aws'

class List < CachedHash
  attr_reader :slug

  def initialize list
    @slug = list
    super "list/#{list}"
  end

  def cached_message_list year, month
    (AWS::S3::S3Object.load_yaml(month_list_key(year, month)) or [])
  end

  def fresh_message_list year, month
    AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{@slug}/message/#{year}/#{month}/").sort
  end

  def cache_message_list year, month, message_list
    AWS::S3::S3Object.store(month_list_key(year, month), message_list.sort.to_yaml, 'listlibrary_archive', :content_type => 'text/plain')
  end

  def thread year, month, call_number
    AWS::S3::S3Object.load_yaml("list/#{@slug}/thread/#{year}/#{month}/#{call_number}")
  end

  def thread_list year, month
    AWS::S3::S3Object.load_yaml(thread_list_key(year, month), "listlibrary_archive")
  end

  def cache_thread_list year, month, thread_list
    AWS::S3::S3Object.store(thread_list_key(year, month), thread_list.to_yaml, 'listlibrary_archive', :content_type => 'text/plain')
  end

  private

  def month_list_key year, month
    "list/#{@slug}/message_list/#{year}/#{month}"
  end

  def thread_list_key year, month
    "list/#{@slug}/thread_list/#{year}/#{month}"
  end
end
