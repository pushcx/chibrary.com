require_relative '../value/summary'

module Chibrary

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
      message_id:  summary.message_id.to_s,
      from:        summary.from,
      n_subject:   summary.n_subject,
      date:        summary.date.rfc2822,
      blurb:       summary.blurb,
    }
  end

  def self.deserialize h
    Summary.new h.fetch(:call_number), h.fetch(:message_id), h.fetch(:from), h.fetch(:n_subject), h.fetch(:date), h.fetch(:blurb)
  end
end

end # Chibrary
