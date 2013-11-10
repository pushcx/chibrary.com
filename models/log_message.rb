class LogMessage #< ActiveRecord::Base
  attr_accessor :server, :pid, :worker, :key, :status, :message

  #validates_presence_of :server, :pid, :worker, :key, :status, :message
  #validates_numericality_of :server, :pid
end
