require_relative 'thread_link'

class TimeSort
  attr_reader :sym, :threads

  def initialize sym, threads=[]
    @sym = sym
    @threads = threads.map { |t|
      ThreadLink.new(sym, t[:call_number], t[:subject])
    }
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
      thread_set.sym,
      thread_set.root_set.map { |t| { call_number: t.call_number, subject: t.n_subject } }
    )
  end
end
