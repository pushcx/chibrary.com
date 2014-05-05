require_relative '../model/thread_set'
require_relative 'message_container_repo'

# Note this does not include RiakRepo as it delegates all the heavy lifting
# to other Repo classes.

class ThreadSetRepo
  attr_reader :thread_set

  def initialize thread_set
    @thread_set = thread_set
  end

  def store
    thread_set.finish
    each do |thread|
      SummaryContainerRepo.new(thread).store
    end
    ThreadCountRepo.new(MonthCount.for(thread_set)).store
    TimeSortRepo.new(TimeSort.from(thread_set)).store
    RedirectMapRepo.new(thread_set.redirect_map).store
  end

  def self.month sym
    threadset = ThreadSet.new(sym)
    MessageContainerRepo.month(sym).each do |thread|
      thread.each { |c| threadset.containers[c.message_id] = c }
    end
    threadset
  end
end
