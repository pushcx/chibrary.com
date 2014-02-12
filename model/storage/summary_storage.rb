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

  def serialize
    {
      call_number: summary.call_number.to_s,
      n_subject:   summary.n_subject,
      date:        summary.date.rfc2822,
      blurb:       summary.blurb,
    }
  end

  def deserialize h
    Summary.new h[:call_number], h[:n_subject], h[:date], h[:blurb]
  end
end
