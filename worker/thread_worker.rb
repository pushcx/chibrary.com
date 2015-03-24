require 'sidekiq'

require_relative '../value/call_number'
require_relative '../entity/thread'
require_relative '../repo/message_repo'
require_relative '../repo/thread_repo'

module Chibrary

class ThreadWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :thread

  def perform call_numbers
    call_numbers.each { |cn| thread CallNumber.new(cn) }
  end

  def thread call_number
    message = MessageRepo.find(call_number)
    thread = ThreadRepo.thread_for message
    thread << message
    ThreadRepo.new(thread).store
    # find stragglers
    thread
  end
end

end # Chibrary
