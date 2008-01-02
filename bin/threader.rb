#!/usr/bin/ruby

require 'ostruct'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'
require 'list'
require 'threading'

class Threader
  attr_accessor :jobs, :stop_on_empty

  def initialize
    @jobs = []
    @stop_on_empty = false
  end

  def get_job
    if @jobs.empty?
      exit if @stop_on_empty
      @jobs = AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'thread_queue/')
    end
    @jobs.pop
  end

  def run
    while job = get_job
      slug, year, month = job.key.split('/')[1..-1]
      job.delete
      $stdout.puts "#{slug}/#{year}/#{month}"

      message_cache = AWS::S3::S3Object.load_yaml("list/#{slug}/message/#{year}/#{month}/") or []
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
        threadset << messages.last
      end

      cache_work(slug, year, month, message_list, threadset) unless removed.empty? and added.empty?
    end
  end

  def cache_work(slug, year, month, message_list, threadset)
    render_queue = CachedHash.new("render_queue")
    render_month = CachedHash.new("render/month/#{slug}")
    AWS::S3::S3Object.store(
      "list/#{slug}/message/#{year}/#{month}",
      message_list.sort.to_yaml,
      'listlibrary_archive',
      :content_type => 'text/plain'
    )

    threads = threadset.collect do |thread|
      name = "#{year}/#{month}/#{thread.call_number}"
      yaml = thread.to_yaml
      begin
        o = AWS::S3::S3Object.find("list/#{slug}/thread/#{name}", 'listlibrary_archive')
        cached = o.about["content-length"] == yaml.size
      rescue
        cached = false
      end

      next if cached

      render_queue["#{slug}/#{name}"] = ''
      AWS::S3::S3Object.store(
        "list/#{slug}/thread/#{name}",
        yaml,
        'listlibrary_archive',
        :content_type => 'text/plain'
      )

      { :call_number => thread.call_number, :subject => thread.subject, :messages => thread.count }
    end

    render_month["#{year}/#{month}"] = threads.to_yaml
  end
end

if __FILE__ == $0
  t = Threader.new
  ARGV.each do |job|
    t.stop_on_empty = true
    AWS::S3::S3Object.delete("thread_queue/#{job}", 'listlibrary_cachedhash')
    t.jobs << OpenStruct.new(:key => "thread_queue/#{job}", :delete => nil)
  end
  t.run
end
