require 'sidekiq'

require_relative '../lib/core_ext/time_'
require_relative '../value/sym'
require_relative '../model/thread_set'
require_relative '../repo/call_number_list_repo'
require_relative '../repo/message_repo'
require_relative '../repo/thread_set_repo'

class ThreadWorker
  include Sidekiq::Worker

  def perform slug, year, month
    thread(Sym.new(slug, year, month))
  end

  def thread sym
    cached_message_list = CallNumberListRepo.find sym
    fresh_message_list  = MessageRepo.call_number_list sym

    if cached_message_list == fresh_message_list
      puts "nothing to do"
      return
    end

    # if any messages were removed, rebuild for safety over the speed of find and remove
    removed = (cached_message_list - fresh_message_list)
    if !removed.empty?
      threadset = ThreadSet.new(sym)
      added = fresh_message_list
    else
      threadset = ThreadSetRepo.month(sym)
      added = fresh_message_list - cached_message_list
      puts "#{fresh_message_list.size} messages, #{cached_message_list .size} in cache, adding #{added.size}"
    end

    # add messages
    added.each do |call_number|
      threadset << MessageRepo.find(call_number)
    end

    return if removed.empty? and added.empty?

    #threadset.dump
    #threadset.summarize_threads.each {|s| s.dump }
    ThreadSetRepo.new(threadset).store
    CallNumberListRepo.new(sym, fresh_message_list).store
  end
end
