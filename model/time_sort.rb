class TimeSort
  attr_reader :slug, :year, :month
  attr_reader :threads

  def initialize slug, year, month, thread_set=nil
    @slug = slug
    @year = year.to_i
    @month = month.to_i
    if thread_set
      @threads = thread_set.root_set.map { |t|
        ThreadLink.new(slug, year, month, t.call_number, t.n_subject)
      }
    else
      thread_set = []
    end
  end

  def previous_link call_number
    index = threads.index { |tl| tl.call_number == call_number } - 1
    return nil if index == -1
    threads[index]
  end

  def next_link call_number
    index = threads.index { |tl| tl.call_number == call_number } + 1
    return nil if index == threads.count
    threads[index]
  end

  def self.from thread_set
    new(
      thread_set.slug,
      thread_set.date.year,
      thread_set.date.month,
      thread_set
    )
  end
end
