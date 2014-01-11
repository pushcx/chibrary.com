require_relative '../thread_set'
require_relative 'message_container_storage'

# Note this does not include RiakStorage as it delegates all the heavy lifting
# to other Storage classes.

class ThreadSetStorage
  attr_reader :thread_set

  def initialize thread_set
    @thread_set = thread_set
  end

  def store
    thread_set.finish
    each do |thread|
      SummaryContainerStorage.new(thread).store
      # store n/p links
      # store thread/message counts
    end
    @redirected_threads.each do |redirect|
      # store redirect table
    end
  end

  def self.month slug, year, month
    threadset = ThreadSet.new(slug, year, month)
    MessageContainerStorage.month(slug, year, month).each do |thread|
      thread.each { |c| threadset.containers[c.message_id] = c }
    end
    threadset
  end
end
