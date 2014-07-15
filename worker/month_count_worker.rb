require 'sidekiq'

require_relative '../value/call_number'
require_relative '../model/message_container'
require_relative '../repo/sym_repo'
require_relative '../repo/thread_repo'

class MonthCountWorker
  include Sidekiq::Worker

  def perform serialized_sym
    store monthcount of_month identified_by(serialized_sym)
  end

  def identified_by serialized
    SymRepo.deserialize serialized_sym
  end

  def of_month sym
    ThreadRepo.month(sym)
  end

  def monthcount month
    MonthCount.from month
  end

  def store mc
    MonthCountRepo.new(mc).store
  end

end
