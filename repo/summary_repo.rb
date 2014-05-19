require_relative '../value/summary'

# Does not import RiakRepo completely or confirm to the Repo interface
# because Summaries are never loaded individually, only via
# SummaryContainerRepo.
class SummaryRepo
  attr_reader :summary

  def initialize summary
    @summary = summary
  end

  def serialize
    {
      call_number: summary.call_number.to_s,
      from:        summary.from,
      n_subject:   summary.n_subject,
      date:        summary.date.rfc2822,
      blurb:       summary.blurb,
    }
  end

  def self.deserialize h
    Summary.new h[:call_number], h[:from], h[:n_subject], h[:date], h[:blurb]
  end
end
