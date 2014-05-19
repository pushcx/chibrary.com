require 'set'

require_relative '../service/call_number_service'
require_relative '../model/message'
require_relative '../repo/message_repo'
require_relative '../repo/list_address_repo'
require_relative '../worker/thread_worker'

class Filer
  attr_reader :source, :call_number_service, :message_count, :syms_seen

  def initialize source
    @source = source

    @call_number_service = CallNumberService.new
    @message_count = 0
    @syms_seen = Set.new
  end

  def file raw_email, src=nil, list=nil
    call_number = call_number_service.next!
    src ||= source
    message = Message.from_string(raw_email, call_number, src)
    list ||= ListAddressRepo.find_list_by_addresses(message.email.possible_list_addresses)
    mr = MessageRepo.new(message, list, MessageRepo::Overwrite::DO)
    syms_seen << mr.sym
    mr.store
  end

  def thread_jobs
    syms_seen.each do |sym|
      ThreadWorker.perform_async sym.slug, sym.year, sym.month
    end
  end
end
