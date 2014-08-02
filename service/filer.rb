require_relative '../service/call_number_service'
require_relative '../model/message'
require_relative '../repo/message_repo'
require_relative '../repo/list_address_repo'
require_relative '../worker/thread_worker'

module Chibrary

class Filer
  attr_reader :source, :call_number_service, :message_count, :n_subjects_seen

  def initialize source
    @source = source

    @call_number_service = CallNumberService.new
    @message_count = 0
    @filed = {} # n_subject => [call_numbers]
  end

  def file raw_email, src=nil, list=nil
    call_number = call_number_service.next!
    src ||= source
    message = Message.from_string(raw_email, call_number, src)
    list ||= ListAddressRepo.find_list_by_addresses(message.email.possible_list_addresses)
    sym = Sym.new(list.slug, message.date.year, message.date.month)
    message_repo = MessageRepo.new(message, sym, MessageRepo::Overwrite::DO)
    message_repo.store

    filed[message.n_subject] = filed.fetch(message.n_subject, []) << call_number
  end

  def thread_jobs
    filed.each do |n_subject, call_numbers|
      ThreadWorker.perform_async call_numbers
    end
  end
end

end # Chibrary
