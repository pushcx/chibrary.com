#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'tempfile'

class Threader
  def initialize
    @thread_q = Queue.new :thread
  end

  def run
    log = Log.new "Threader"
    log.block "threader" do |threader_log|
    @thread_q.work do |job|
      threader_log.block job.key do |job_log|
      slug, year, month = job[:slug], job[:year], job[:month]
      list = List.new slug

      cached_message_list = list.cached_message_list year, month
      fresh_message_list  = list.fresh_message_list year, month

      if cached_message_list == fresh_message_list
        job_log.status "nothing to do"
        next
      end

      # if any messages were removed, rebuild for safety over the speed of find and remove
      removed = (cached_message_list - fresh_message_list)
      if !removed.empty?
        threadset = ThreadSet.new
        added = fresh_message_list
      else
        threadset = ThreadSet.month(slug, year, month)
        added = fresh_message_list - cached_message_list 
        job_log.status "#{fresh_message_list.size} messages, #{cached_message_list .size} in cache, adding #{added.size}"
      end

      # add messages
      added.each do |key|
        threadset << $archive["list/#{slug}/message/#{year}/#{month}/#{key}"]
      end

      cache_work(slug, year, month, fresh_message_list, threadset) unless removed.empty? and added.empty?
      end # job_log
    end # work loop
    end # threader_log
  end

  def cache_work slug, year, month, message_list, threadset
    threadset.rejoin_splits # rejoins threads split across months and stores

    # cache the message_list (for Threader) and thread_list (for Renderer)
    list = List.new slug
    list.cache_message_list year, month, message_list

    # queue the publish
    @publish_q ||= Queue.new :publish
    @publish_q.add :slug => slug, :year => year, :month => month
    nil
  end
end

begin
  Threader.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
