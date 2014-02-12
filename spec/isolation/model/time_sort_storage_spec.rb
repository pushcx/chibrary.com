require_relative '../../rspec'
require_relative '../../../model/storage/time_sort_storage'

describe TimeSortStorage do
  context 'instantiated with a TimeSort' do
    it "generates a key based on slug, year, and month" do
      ts = TimeSort.new 'slug', 2014, 1
      expect(TimeSortStorage.new(ts).extract_key).to eq('slug/2014/01')
    end

    describe "generating a hash" do
      let(:ts) { ts = TimeSort.new 'slug', 2014, 1, fake_thread_set(['one', 'two']) }
      let(:time_sort_storage) { TimeSortStorage.new(ts) }
      subject { time_sort_storage.serialize }

      it { expect(subject.count).to eq(2) }
      it { expect(subject.first).to eq({
        slug: 'slug',
        year: 2014,
        month: 1,
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
    it "instantiates a list from the bucket" do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('slug').and_return({
        slug: 'slug',
        name: 'name',
      })
      ListStorage.should_receive(:bucket).and_return(bucket)
      list = ListStorage.find('slug')
      expect(list).to be_a(List)
      expect(list.slug).to eq('slug')
      expect(list.name).to eq('name')
    end
  end
end
