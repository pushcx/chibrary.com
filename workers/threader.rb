#!/usr/bin/ruby

require 'aws'
require 'threading'
require 'list'

class Threader
  attr_accessor :render_queue

  def initialize
    @render_queue = CachedHash.new("render_queue")
  end

  def get_job
    AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'threader_queue/', :max_keys => 1).first
  end

  def run
    while job = get_job
      $stdout.puts job.key
      slug, year, month = job.key.split('/')[1..-1]
      job.delete

      message_cache = (AWS::S3::S3Object.load_cache("list/#{slug}/message_cache/#{year}/#{month}") or [])
      message_list  = AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/message/#{year}/#{month}/").sort

      next if message_cache == message_list

      # if any messages were removed, rebuild for saftey over the speed of find and remove
      removed = (message_cache - message_list)
      if !removed.empty?
        threadset = ThreadSet.new
        added = message_list
      else
        threadset = ThreadSet.month(slug, year, month)
        added = message_list - message_cache
        $stdout.puts "#{message_list.size} messages, #{message_cache.size} in cache, adding #{added.size}"
      end

      # add messages
      messages = []
      added.each do |mail|
        messages << Message.new(mail)
        threadset.add_message messages.last
      end

      cache_work(slug, year, month, message_list, threadset) unless removed.empty? and added.empty?
    end
  end

  def cache_work(slug, year, month, message_list, threadset)
    AWS::S3::S3Object.store(
      "list/#{slug}/message_cache/#{year}/#{month}",
      message_list.sort.to_yaml,
      'listlibrary_archive',
      :content_type => 'text/plain'
    )

    threadset.threads.each do |thread|
      name = "#{year}/#{month}/#{thread.first.call_number}"
      yaml = thread.to_yaml
      begin
        o = AWS::S3::S3Object.find("list/#{slug}/thread/#{name}", 'listlibrary_archive')
        cached = o.about["content-length"] == yaml.size
      rescue
        cached = false
      end

      next if cached

      @render_queue["#{slug}/#{name}"] = ''
      AWS::S3::S3Object.store(
        "list/#{slug}/thread/#{name}",
        yaml,
        'listlibrary_archive',
        :content_type => 'text/plain'
      )
    end
  end
end


Threader.new.run if __FILE__ == $0
