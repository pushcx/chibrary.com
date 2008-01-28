require 'rubygems'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'

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
    "#{@type.to_s}/" + JOB_TYPES[@type][:key].gsub(/:(\w+)/) { @attributes[$1.to_sym] }
  end

  def delete
    AWS::S3::S3Object.delete("queue/#{key}", "listlibrary_archive")
  end
end

class Queue
  attr_reader :type

  def initialize type
    raise "unknown job type #{type}" unless JOB_TYPES.has_key? type
    @type = type
    @queue = CachedHash.new("queue/#{type}")
  end

  def add attributes
    job = Job.new @type, attributes
    @queue[job.key] = job.to_yaml
  end

  def next
    while 1
      begin
        object = AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => "queue/#{type}/", :max_keys => 1).first
        return nil if object.nil?
        job = YAML::load(object.value)
        object.delete
        break
      rescue
        # another worker took this job, try again
      end
    end
    job
  end
end
