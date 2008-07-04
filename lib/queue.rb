require 'rubygems'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'storage'
require 'cachedhash'

JOB_TYPES = {
  :thread => {
    :key => ":slug/:year/:month",
  },
  :render_static => {
    :key => '',
  },
  :render_list => {
    :key => ":slug",
  },
  :render_month => {
    :key => ":slug/:year/:month",
  },
  :render_thread => {
    :key => ":slug/:year/:month/:call_number",
  },
}

class Job
  attr_accessor :type, :attributes

  def initialize type, attributes
    raise "unknown job type #{type}" unless JOB_TYPES.has_key? type
    @type = type
    @attributes = attributes
  end

  def [] k ; @attributes[k] ; end

  def key
    JOB_TYPES[@type][:key].gsub(/:(\w+)/) { @attributes[$1.to_sym] }
  end

  def delete
    $archive.delete["queue/#{key}"]
  end
end

class Queue
  attr_reader :type

  def initialize type
    raise "unknown job type #{type}" unless JOB_TYPES.has_key? type
    @type = type
    @queue = CachedHash.new("queue/#{@type}")
  end

  def add attributes
    job = Job.new @type, attributes
    @queue[job.key] = job.to_yaml
  end

  def work
    queue = $cachedhash["queue/#{@type}"]
    in_progress = $cachedhash["in_progress/#{@type}"]
    while 1
      while 1
        begin
          key = queue.first
          return nil if key.nil?
          job = queue[key]
          puts key
          queue.delete key
          in_progress[key] = job
          break
        rescue Exception => e
          # another worker took this job, try again
        end
      end

      begin
        yield job
      rescue Exception => e
        queue[key] = job
        in_progress.delete key
        puts "returning #{key} to queue, caught: #{e.class} #{e}\n" + e.backtrace.join("\n")
        return nil # stop execution
      else
        in_progress.delete key
      end
    end
  end
end
