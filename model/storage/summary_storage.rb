require 'time'

require_relative '../summary'

# Does not import RiakStorage completely or confirm to the Storage interface
# because Summaries are never loaded individually, only via
# SummaryContainerStorage.
class SummaryStorage
  attr_reader :summary

  def initialize summary
    @summary = summary
  end

  def to_hash
    {
      call_number: summary.call_number.to_s,
      n_subject:   summary.n_subject,
      date:        summary.date.rfc2822,
    }
  end

  def from_hash h
    Summary.new h[:call_number], h[:n_subject], h[:date]
  end
end
