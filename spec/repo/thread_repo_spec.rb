require_relative '../rspec'
require_relative '../../model/thread'
require_relative '../../repo/message_repo'
require_relative '../../repo/thread_repo'

module Chibrary

describe ThreadRepo do
  let(:message) { OpenStruct.new(
    slug: 'slug',
    date: Time.new(2014, 9, 26, 14, 45),
    call_number: 'callnum1',
    message_id: '1@example.com',
    n_subject: 'subject',
    body: '',
  ) }
  let(:t) { Thread.new 'slug', [message] }

  context 'instantiated with a Thread' do
    describe '#serialize' do
      let(:thread_repo) { ThreadRepo.new(t) }
      before { SummaryContainerRepo.should_receive(:new).and_return(double('summary_container_repo', serialize: { 'a' => 'b' })) }
      subject { thread_repo.serialize }

      it { expect(subject[:slug]).to eq('slug') }
      it { expect(subject[:containers]).to eq({ 'a' => 'b' }) }
    end

    describe "#indexes" do
      let(:thread_repo) { ThreadRepo.new(t) }
      subject { thread_repo.indexes }

      it { expect(subject[:slug_bin]).to eq('slug') }
      it { expect(subject[:sym_bin]).to eq('slug/2014/09') }
      it { expect(subject[:slug_timestamp_next_bin]).to eq('slug_1411760700') }
      it { expect(subject[:slug_timestamp_prev_bin]).to eq('slug_8588239300') }
      it { expect(subject[:call_number_bin]).to eq(['Y2FsbG51bTE=']) }
      it { expect(subject[:message_id_bin]).to eq(['MUBleGFtcGxlLmNvbQ==']) }
      it { expect(subject[:n_subject_bin]).to eq(['c3ViamVjdA==']) }
    end

    it "#extract_key is based on CallNumber" do
      expect(ThreadRepo.new(t).extract_key).to eq('callnum1')
    end

    describe '#next_thread' do
      it "finds the next Thread by time" do
        tr = ThreadRepo.new(t)
        bucket = double('bucket')
        bucket.should_receive(:get_index).with("slug_timestamp_next_bin", "slug_1411760701".."~~~~~~~~~~~~~~~", {:max_results=>1}).and_return(['callnext'])
        tr.should_receive(:bucket).and_return(bucket)
        tr.should_receive(:find).with('callnext').and_return(:next)
        expect(tr.next_thread).to eq(:next)
      end

      it "returns nil if there's no next Thread" do
        tr = ThreadRepo.new(t)
        bucket = double('bucket')
        bucket.should_receive(:get_index).with("slug_timestamp_next_bin", "slug_1411760701".."~~~~~~~~~~~~~~~", {:max_results=>1}).and_return([])
        tr.should_receive(:bucket).and_return(bucket)
        expect(tr.next_thread).to eq(nil)
      end
    end

    describe '#previous_thread' do
      it "finds the previous Thread by time" do
        tr = ThreadRepo.new(t)
        bucket = double('bucket')
        bucket.should_receive(:get_index).with("slug_timestamp_prev_bin", "slug_8588239301".."~~~~~~~~~~~~~~~", {:max_results=>1}).and_return(['callprev'])
        tr.should_receive(:bucket).and_return(bucket)
        tr.should_receive(:find).with('callprev').and_return(:prev)
        expect(tr.previous_thread).to eq(:prev)
      end

      it "returns nil if there's no previous Thread" do
        tr = ThreadRepo.new(t)
        bucket = double('bucket')
        bucket.should_receive(:get_index).with("slug_timestamp_prev_bin", "slug_8588239301".."~~~~~~~~~~~~~~~", {:max_results=>1}).and_return([])
        tr.should_receive(:bucket).and_return(bucket)
        expect(tr.previous_thread).to eq(nil)
      end
    end

  end

  it '::build_key builds based on CallNumber' do
    expect(ThreadRepo.build_key('callnumb')).to eq('callnumb')
  end

  it '::deserialize Thread' do
    sc = SummaryContainerRepo.new(Container.new('1@example.com', Summary.new('callnumb', '1@example.com', 'f1@example.com', 'n 1', Time.now, 'blurb 1')))
    hash = {
      'slug' => 'slug',
      'containers' => sc.serialize,
    }
    thread = ThreadRepo.deserialize(hash)
    expect(thread.slug).to eq('slug')
    expect(thread.root.call_number).to eq('callnumb')
  end

  describe "::find" do
    it "instantiates a Thread from the bucket" do
      sc = SummaryContainerRepo.new(Container.new('1@example.com', Summary.new('callnumb', '1@example.com', 'f1@example.com', 'n 1', Time.now, 'blurb 1')))
      bucket = double('bucket')
      bucket.should_receive(:[]).with('slug').and_return({
        'slug' => 'slug',
        'containers' => sc.serialize,
      })
      ThreadRepo.should_receive(:bucket).and_return(bucket)
      thread = ThreadRepo.find('slug')
      expect(thread).to be_a(Thread)
      expect(thread.slug).to eq('slug')
    end
  end

  describe "::root_for" do
    it "finds the CallNumber for the root of the Thread" do
      bucket = double('bucket')
      bucket.should_receive(:get_index).with('call_number_bin', Base64.strict_encode64('callrepl')).and_return(['callroot'])
      ThreadRepo.should_receive(:bucket).and_return(bucket)
      expect(ThreadRepo.root_for 'callrepl').to eq('callroot')
    end

    it "raises NotFound if it can't find the thread" do
      bucket = double('bucket')
      bucket.should_receive(:get_index).with('call_number_bin', Base64.strict_encode64('callrepl')).and_return([])
      ThreadRepo.should_receive(:bucket).and_return(bucket)
      expect {
        ThreadRepo.root_for 'callrepl'
      }.to raise_error(NotFound)
    end

    it "raises TooManyFound if a CallNumber has been threaded twice" do
      bucket = double('bucket')
      bucket.should_receive(:get_index).with('call_number_bin', Base64.strict_encode64('callrepl')).and_return(['callroot', 'callothr'])
      ThreadRepo.should_receive(:bucket).and_return(bucket)
      expect {
        ThreadRepo.root_for 'callrepl'
      }.to raise_error(TooManyFound)
    end
  end

  describe "::find_with_messages" do
    it "finds a Thread and hydrates it with Messages" do
      ThreadRepo.should_receive(:find).and_return(t)
      MessageRepo.should_receive(:find_all).with(['callnum1']).and_return({'callnum1' => message})
      thread = ThreadRepo.find_with_messages('callnumb')
      expect(thread.root.value).to eq(message)
    end
  end

  describe "::find_all" do
    it "finds multiple Threads"
    it "raises if any key is not found"
  end

  describe "::threads_by_message_id"
  describe "::threads_by_n_subject"

  describe "::month" do
    it "loads all the Threads for a month view"
  end

  describe "::thread_for_message" do
    it "finds the Thread a Message should be added to"
  end

  describe "::potential_threads_for" do
    it "finds candidate Threads for adding a Message to"
  end
end

end # Chibrary
