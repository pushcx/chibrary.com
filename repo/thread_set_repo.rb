require_relative '../model/thread_set'
require_relative 'message_container_repo'
require_relative 'month_count_repo'
require_relative 'redirect_map_repo'
require_relative 'summary_container_repo'
require_relative 'time_sort_repo'

# Note this does not include RiakRepo as it delegates all the heavy lifting
# to other Repo classes.

class ThreadSetRepo
  attr_reader :thread_set

  def initialize thread_set
    @thread_set = thread_set
  end

  def store
    SummarySetRepo.new(thread_set.summarize_threads).store
    MonthCountRepo.new(MonthCount.from(thread_set)).store
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
