#!/usr/bin/env ruby

require 'tempfile'

require_relative '../model/container'
require_relative '../model/message'
require_relative '../model/queue'
require_relative '../model/list'
require_relative '../model/thread_list'
require_relative '../model/thread_set'
require_relative '../lib/log'
require_relative '../lib/time_'

class Threader
  def initialize
    @thread_q = Queue.new :thread
  end

  def run
    log = Log.new "Threader"
    log.block "threader" do |threader_log|
    @thread_q.work do |job|
      threader_log.block job.key do |job_log|
      sym = job.sym
      list = List.new slug

      cached_message_list = CallNumberListStorage.find sym
      fresh_message_list  = MessageStorage.call_number_list sym

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
        threadset = ThreadSet.month(sym)
        added = fresh_message_list - cached_message_list 
        job_log.status "#{fresh_message_list.size} messages, #{cached_message_list .size} in cache, adding #{added.size}"
      end

      # add messages
      added.each do |call_number|
        threadset << MessageStorage.find call_number
      end

      return if removed.empty? and added.empty?

      # Many threads are split by replies in later months. This rejoins them.
      threadset.prior_months.each do |s|
        # Rejoin any threads from later months
        ts = ThreadSetStorage.month(s)
        ts.retrieve_split_threads_from threadset
        ThreadSetStorage.new(ts).store
      end
      threadset.following_months.each do |s|
        # And move threads up to earlier months when possible
        ts = ThreadSetStorage.month(s)
        threadset.retrieve_split_threads_from ts
        ThreadSetStorage.new(ts).store
      end
      ThreadSetStorage.new(threadset).store

      cache_work(sym, fresh_message_list)

      end # job_log
    end # work loop
    end # threader_log
  end

  def cache_work sym, message_list
    # cache the message_list (for Threader) and thread_list (for Renderer)
    list = List.new slug
    CallNumberListStorage.new(sym, message_list).store
    nil
  end
end

begin
  Threader.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
