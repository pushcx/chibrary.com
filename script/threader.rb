#!/usr/bin/env ruby

require_relative '../worker/thread_worker'
require_relative '../value/sym'

begin
  sym = Chibrary::Sym.new('mud-dev', 2000, 1)
  Chibrary::ThreadWorker.new.thread(sym) if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
