require_relative '../lib/core_ext/ice_nine_'

class MonthCount
  prepend IceNine::DeepFreeze

  attr_reader :sym, :thread_count, :message_count

  def initialize sym, thread_count=0, message_count=0
    @sym, @thread_count, @message_count = sym, thread_count, message_count
  end

  def empty?
    thread_count == 0 and message_count == 0
  end

  def == mc
    mc.sym == sym and mc.thread_count == thread_count and mc.message_count == message_count
  end

  def self.from ts
    new ts.sym, ts.thread_count, ts.message_count
  end
end
