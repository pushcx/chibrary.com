require_relative '../../rspec'
require_relative '../../../model/storage/time_sort_storage'

describe TimeSortStorage do
  context 'instantiated with a TimeSort' do
    it "generates a key based on slug, year, and month" do
      ts = TimeSort.new 'slug', 2014, 1
      expect(TimeSortStorage.new(ts).extract_key).to eq('slug/2014/01')
    end

    describe "generating a hash" do
      let(:ts) { ts = TimeSort.from fake_thread_set(['one', 'two']) }
      let(:time_sort_storage) { TimeSortStorage.new(ts) }
      subject { time_sort_storage.serialize }

      it { expect(subject.count).to eq(2) }
      it { expect(subject.first).to eq({
        call_number: 'one',
        subject: 'subject one',
      }) }
    end
  end

  describe "::build_key" do
    it "builds a key based on slug" do
      expect(TimeSortStorage.build_key('slug', 2014, 1)).to eq('slug/2014/01')
    end
  end

  describe "::find" do
    it "instantiates a TimeSort from the bucket" do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('slug/2014/04').and_return([
        {
          call_number: 'aaaaaaaa',
          subject: 'subject one',
        },
      ])
      TimeSortStorage.should_receive(:bucket).and_return(bucket)
      ts = TimeSortStorage.find('slug', 2014, 4)
      expect(ts).to be_a(TimeSort)
      expect(ts.slug).to eq('slug')
      expect(ts.year).to eq(2014)
      expect(ts.month).to eq(4)
      expect(ts.threads.count).to eq(1)
      tl = ts.threads.first
      expect(tl.slug).to eq('slug')
      expect(tl.call_number).to eq('aaaaaaaa')
      expect(tl.subject).to eq('subject one')
    end
  end
end
