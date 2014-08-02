require_relative '../rspec'
require_relative '../../lib/core_ext/time_'

module Chibrary

describe Time do
  let(:base_time) { Time.utc(2007, 9, 11) }

  it 'can add and subtract years' do
    [
      [1,  2008, 9],
      [-1, 2006, 9],
    ].each do |delta, year, month|
      time = base_time.plus_year(delta)
      expect(time.year).to  eq(year)
      expect(time.month).to eq(month)
    end
  end

  it 'can add and subtract months' do
    [
      [1,  2007, 10],
      [-1, 2007, 8],
      [4,  2008, 1],
      [-9, 2006, 12],
    ].each do |delta, year, month|
      time = base_time.plus_month(delta)
      expect(time.year).to  eq(year)
      expect(time.month).to eq(month)
    end
  end

  it 'can add and subtract days' do
    [
      [1,   2007, 9,  12],
      [-1,  2007, 9,  10],
      [20,  2007, 10, 1],
      [-11, 2007, 8,  31],
    ].each do |delta, year, month, day|
      time = base_time.plus_day(delta)
      expect(time.year).to  eq(year)
      expect(time.month).to eq(month)
      expect(time.day).to   eq(day)
    end
  end
end

end # Chibrary
