require 'sidekiq'

require_relative '../value/month_count'
require_relative '../repo/month_count_repo'
require_relative '../repo/sym_repo'
require_relative '../repo/thread_repo'

module Chibrary

class MonthCountWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :month_count

  def perform serialized_sym
    store monthcount of_month identified_by(serialized_sym)
  end

  def identified_by serialized_sym
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

end # Chibrary
