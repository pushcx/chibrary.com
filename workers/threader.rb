#!/usr/bin/ruby

require 'aws'
require 'threading'
require 'yaml'

class Threader
  attr_accessor :render_queue

  def initialize
    @render_queue = CachedHash.new("render_queue")
  end

  def get_job
    AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'threader_queue/', :max_keys => 1).first
  end

  def load_cache key
    begin
      YAML::load(AWS::S3::S3Object.value(key, 'listlibrary_archive'))
    rescue AWS::S3::NoSuchKey
      nil
    end
  end

  def run
    while job = get_job
      puts job.key + " " + "*" * 50
      slug, year, month = job.key.split('/')[1..-1]
      job.delete

      puts "loading caches"
      message_cache = (load_cache("list/#{slug}/threading/#{year}/#{month}/message_cache") or [])
      threads       = (load_cache("list/#{slug}/threading/#{year}/#{month}/threadset") or ThreadSet.new)

      puts "loading message list"
      messages      = AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/message/#{year}/#{month}/")

      # if any messages were removed, rebuild for saftey over the speed of find and remove
      if (message_cache - messages).empty?
        added = messages - message_cache
      else
        puts "rebuilding!"
        threads = ThreadSet.new
        added = messages
      end
      puts "#{messages.size} messages, #{message_cache.size} in cache, adding #{added.size}"
      i = 0
      added.each { |mail| threads.add_message Message.new(mail) ; i += 1 ; puts "#{i} " if i % 100 == 0 }
      puts "caching"
      unless added.empty?
        AWS::S3::S3Object.store("list/#{slug}/threading/#{year}/#{month}/message_cache", messages.to_yaml, 'listlibrary_archive', :content_type => 'text/plain')
        AWS::S3::S3Object.store("list/#{slug}/threading/#{year}/#{month}/threadset",     threads.to_yaml,  'listlibrary_archive', :content_type => 'text/plain')
      end
      # track and rerender messages, threads, monthly archive, home page
    end
  end
end


Threader.new.run if __FILE__ == $0
