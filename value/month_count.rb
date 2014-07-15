require 'adamantium'

class MonthCount
  include Adamantium

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

  def self.from month
    new month.first.sym, month.count, month.map(&:message_count).inject(&:+)
  end
end
