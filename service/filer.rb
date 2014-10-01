require_relative '../service/call_number_service'
require_relative '../model/message'
require_relative '../repo/message_repo'
require_relative '../repo/list_address_repo'
require_relative '../worker/thread_worker'

module Chibrary

class Filer
  attr_reader :source
  attr_reader :call_number_service, :message_count, :filed

  def initialize source
    @source = source

    @call_number_service = CallNumberService.new
    @message_count = 0
    @filed = {} # n_subject => [call_numbers]
  end

  def file raw_email, slug=nil, src=nil
    call_number = call_number_service.next!
    src ||= source
    list = ListRepo.for slug, Email.new(raw_email).possible_list_addresses
    message = Message.from_string(raw_email, call_number, list.slug, src)
    message.generate_message_id if MessageRepo.has_message_id? message.message_id
    message_repo = MessageRepo.new(message)
    message_repo.store

    filed[message.n_subject] = filed.fetch(message.n_subject, []) << call_number
  end

  def thread_jobs
    filed.each do |n_subject, call_numbers|
      ThreadWorker.perform_async call_numbers
    end
    @filed = {}
  end
end

end # Chibrary
