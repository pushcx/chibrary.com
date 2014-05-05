require_relative '../../rspec'
require_relative '../../../model/sum_count'

SCTestMonthCount = Struct.new(:thread_count, :message_count)

describe SumCount do
  describe '::of' do
    it 'creates from an array of MonthCounts' do
      month_counts = [
        SCTestMonthCount.new(1, 3),
        SCTestMonthCount.new(2, 5),
      ]
      sc = SumCount.of(month_counts)
      expect(sc.thread_count).to eq(3)
      expect(sc.message_count).to eq(8)
    end
  end
end
