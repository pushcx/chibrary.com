require 'sidekiq'

require_relative '../value/call_number'
require_relative '../model/thread'
require_relative '../model/message_container'
require_relative '../repo/message_repo'
require_relative '../repo/thread_repo'

module Chibrary

class ThreadWorker
  include Sidekiq::Worker

  def initialize
  end

  def perform call_numbers
    call_numbers.each { |cn| thread CallNumber.new(cn) }
  end

  def thread_for_message message
    ThreadRepo.potential_threads_for(message) do |thread|
      #next unless thread.sym.slug == ListAddressRepo.find_list_by_addresses(message.email.possible_list_addresses).slug
      return thread if thread.conversation_for? message
    end
    Thread.new MessageContainer.new(message)
  end

  def thread call_number
    message = MessageRepo.find(call_number)
    thread = thread_for_message message
    thread << message
    ThreadRepo.new(thread).store
  end
end

end # Chibrary
