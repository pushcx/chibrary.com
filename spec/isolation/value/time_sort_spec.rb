require_relative '../../rspec'
require_relative '../../../value/time_sort'

describe TimeSort do
  describe '#previous' do
    it 'finds the previous thread' do
      ts = TimeSort.from fake_thread_set(['one', 'two', 'three'])
      expect(ts.previous_link('three').call_number).to eq('two')
      expect(ts.previous_link('two').call_number).to eq('one')
    end

    it 'returns nil on first thread' do
      ts = TimeSort.from fake_thread_set(['one', 'two', 'three'])
      expect(ts.previous_link('one')).to eq(nil)
    end
  end

  describe '#next' do
    it 'finds the next thread' do
      ts = TimeSort.from fake_thread_set(['one', 'two', 'three'])
      expect(ts.next_link('one').call_number).to eq('two')
      expect(ts.next_link('two').call_number).to eq('three')
    end

    it 'returns nil on last thread' do
      ts = TimeSort.from fake_thread_set(['one', 'two', 'three'])
      expect(ts.next_link('three')).to eq(nil)
    end
  end

  describe '::from' do
    CallNumberContainer = Struct.new(:call_number)

    it 'grabs root call numbers from a ThreadSet' do
      ts = TimeSort.from fake_thread_set(['callnumbr1', 'callnumbr2'])
      expect(ts.threads.first.call_number).to eq('callnumbr1')
      expect(ts.threads.last.call_number).to eq('callnumbr2')
    end
  end
end
