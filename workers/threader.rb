#!/usr/bin/ruby

require 'aws'
require 'yaml'

class Threader
  attr_accessor :S3Object

  def initialize
    @bucket   = AWS::S3::Bucket.find('listlibrary_cachedhash')
    @S3Object = AWS::S3::S3Object
    @render_queue = CachedHash.new("render_queue")
  end

  def get_job
    @bucket.objects(:reload, :prefix => 'threader_queue/', :max_keys => 1).first
  end

  def load_cache key
    begin
      YAML::load(@S3Object.find(key).value)
    rescue AWS::S3::NoSuchKey
      []
    end
  end

  def run
    while job = get_job
      slug, year, month = job.key.split('/')[1..-1]
      job.delete

      message_cache = load_cache "list/#{slug}/threading/#{year}/#{month}/message_cache"
      threads       = load_cache "list/#{slug}/threading/#{year}/#{month}/threads"

      messages      = AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/message/#{year}/#{month}/")

      # if any messages were removed, rebuild for saftey over find and remove
      added = message_cache - messages
      unless (messages - message_cache).empty?
        threads = ThreadSet.new
        added = []
      end
      added.each { |mail| threads.add_message Message.new(mail) }
      @S3Object.store("list/#{slug}/threading/#{year}/#{month}/message_cache", messages.to_yaml)
      @S3Object.store("list/#{slug}/threading/#{year}/#{month}/threads",       threads.to_yaml)
      # track and rerender messages, threads, monthly archive, home page
    end
  end
end


#Threader.new.run if __FILE__ == $0
