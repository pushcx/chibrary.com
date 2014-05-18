require 'adamantium'

SumCount = Struct.new(:thread_count, :message_count) do
  include Adamantium

  def self.of month_counts
    SumCount.new(
      month_counts.map(&:thread_count).inject(0, &:+),
      month_counts.map(&:message_count).inject(0, &:+)
    )
  end
end
