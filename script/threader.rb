#!/usr/bin/env ruby

require_relative '../worker/thread_worker'
require_relative '../value/sym'
require_relative '../model/message'
require_relative '../model/thread_set'
require_relative '../repo/call_number_list_repo'
require_relative '../repo/message_repo'
require_relative '../repo/thread_set_repo'
require_relative '../lib/core_ext/time_'

begin
  ThreadWorker.new.thread(Sym.new('mud-dev', 2000, 1)) if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
