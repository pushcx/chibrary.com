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
    rescue
      nil
    end
  end

  def run
    while job = get_job
      $stdout.puts job.key
      slug, year, month = job.key.split('/')[1..-1]
      job.delete

      message_cache = (load_cache("list/#{slug}/threading/#{year}/#{month}/message_cache") or [])
      message_list  = AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/message/#{year}/#{month}/").sort

      next if message_cache == message_list

      threadset     = (load_cache("list/#{slug}/threading/#{year}/#{month}/threadset") or ThreadSet.new)

      # if any messages were removed, rebuild for saftey over the speed of find and remove
      removed = (message_cache - message_list)
      if !removed.empty?
        threadset = ThreadSet.new
        added = message_list
      else
        added = message_list - message_cache
        $stdout.puts "#{message_list.size} messages, #{message_cache.size} in cache, adding #{added.size}"
        next if added.empty?
      end

      # add messages
      messages = []
      added.each do |mail|
        messages << Message.new(mail)
        threadset.add_message messages.last
      end

      # queue renderer
      if !removed.empty?
        # possibly remove threads
        @render_queue["#{slug}/threads/#{year}/#{month}"] = ''
      else
        # or just render all the threads added to
        messages.collect { |m| threadset.thread_for m }.uniq.each do |thread|
          @render_queue["#{slug}/thread/#{thread.first.call_number}"] = ''
        end
      end

      unless added.empty?
        AWS::S3::S3Object.store("list/#{slug}/threading/#{year}/#{month}/message_cache", message_list.sort.to_yaml, 'listlibrary_archive', :content_type => 'text/plain')
        AWS::S3::S3Object.store("list/#{slug}/threading/#{year}/#{month}/threadset",     threadset.to_yaml,  'listlibrary_archive', :content_type => 'text/plain')
      end
    end
  end
end


Threader.new.run if __FILE__ == $0
