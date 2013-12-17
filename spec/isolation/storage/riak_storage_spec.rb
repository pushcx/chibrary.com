require_relative '../../rspec'
require_relative '../../../model/storage/riak_storage'

describe RiakStorage do

  class ExampleStorage
    include RiakStorage
    def extract_key ; '/key' ; end
    def to_hash ; {} ; end
  end

  it 'gives the storage class a bucket named for the model' do
    client = double('client')
    client.should_receive('bucket').with('example').and_return(double('bucket', name: 'example'))
    ExampleStorage.should_receive(:db_client).and_return(client)
    expect(ExampleStorage.new.bucket.name).to eq('example')
  end

  describe "#store" do
    it "puts it in the bucket" do
      es = ExampleStorage.new
      bucket = double('bucket')
      bucket.should_receive(:[]=).with('/key', {})
      es.should_receive(:bucket).and_return(bucket)
      es.store
    end

  end

  describe 'incomplete user' do
    class IncompleteStorage
      include RiakStorage
      # missing .build_key, #extract_key, #to_hash
    end

    it "raises on calls to ::build_key" do
      expect { IncompleteStorage.build_key }.to raise_error(NotImplementedError)
    end

    it "raises on calls to #extract_key" do
      expect { IncompleteStorage.new.extract_key }.to raise_error(NotImplementedError)
    end

    it "raises on calls to #to_hash" do
      expect { IncompleteStorage.new.to_hash }.to raise_error(NotImplementedError)
    end
  end

  describe '#bucket' do
    it 'delegates to .bucket' do
      b = double('bucket')
      ExampleStorage.should_receive(:bucket).and_return(b)
      expect(ExampleStorage.new.bucket).to eq(b)
    end
  end

end
