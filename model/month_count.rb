class MonthCount
  attr_reader :slug, :year, :month
  attr_reader :thread_count, :message_count

  def initialize slug, year, month, thread_count=0, message_count=0
    @slug, @year, @month = slug, year.to_i, month.to_i
    @thread_count, @message_count = thread_count, message_count
  end

  def self.from ts
    new ts.slug, ts.year, ts.month, ts.thread_count, ts.message_count
  end
end
