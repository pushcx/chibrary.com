#!/usr/bin/ruby

require 'ostruct'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'
require 'list'
require 'log'
require 'queue'
require 'threading'

class Threader
  attr_accessor :jobs, :stop_on_empty

  def initialize
    @thread_q = Queue.new :thread
  end

  def get_job
    @thread_q.next
  end

  def run
    Log << "Threader: run"
    while job = get_job
      Log << job.key
      slug, year, month = job[:slug], job[:year], job[:month]

      message_list_cache = (AWS::S3::S3Object.load_yaml("list/#{slug}/message_list/#{year}/#{month}/") or [])
      message_list  = AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/message/#{year}/#{month}/").sort

      if message_list_cache == message_list
        Log << "nothing to do"
        next
      end

      # if any messages were removed, rebuild for saftey over the speed of find and remove
      removed = (message_list_cache - message_list)
      if !removed.empty?
        threadset = ThreadSet.new
        added = message_list
      else
        threadset = ThreadSet.month(slug, year, month)
        added = message_list - message_list_cache
        Log << "#{message_list.size} messages, #{message_list_cache.size} in cache, adding #{added.size}"
      end

      # add messages
      messages = []
      added.each do |mail|
        messages << Message.new(mail)
        threadset << messages.last
      end

      cache_work(slug, year, month, message_list, threadset) unless removed.empty? and added.empty?
      queue_renderer(slug, year, month, threadset) unless removed.empty? and added.empty?
      Log << "job done"
    end
  Log << "Threader: done"
  end

  def cache_work slug, year, month, message_list, threadset
    render_month = CachedHash.new("render/month/#{slug}")
    AWS::S3::S3Object.store(
      "list/#{slug}/message_list/#{year}/#{month}",
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

  def queue_renderer slug, year, month, threadset
    thread_q = Queue.new :render_thread
    threadset.each { |thread| thread_q.add :slug => slug, :year => year, :month => month, :call_number => thread.call_number }
    Queue.new(:render_month).add :slug => slug, :year => year, :month => month
    Queue.new(:render_list).add :slug => slug
  end
end

Threader.new.run if __FILE__ == $0
