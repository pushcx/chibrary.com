class MonthCount
  attr_reader :sym, :thread_count, :message_count

  def initialize sym, thread_count=0, message_count=0
    @sym, @thread_count, @message_count = sym, thread_count, message_count
  end

  def self.from ts
    new ts.sym, ts.thread_count, ts.message_count
  end
end
