require_relative '../rspec'
require_relative '../../repo/riak_repo'

module Chibrary

describe RiakRepo do

  class ExampleRepo
    include RiakRepo
    def extract_key ; '/key' ; end
    def serialize ; {} ; end
  end

  it 'gives the repo class a bucket named for the model' do
    client = double('client')
    client.should_receive('bucket').with('example').and_return(double('bucket', name: 'example'))
    ExampleRepo.should_receive(:db_client).and_return(client)
    expect(ExampleRepo.new.bucket.name).to eq('example')
  end

  describe "#store" do
    it "puts it in the bucket" do
      es = ExampleRepo.new
      object = double('object')
      object.should_receive(:key=).with('/key')
      object.should_receive(:data=).with({})
      object.should_receive(:store)
      bucket = double('bucket')
      bucket.should_receive(:new).and_return(object)
      es.should_receive(:bucket).and_return(bucket)
      es.store
    end

  end

  describe 'incomplete user' do
    class IncompleteRepo
      include RiakRepo
      # missing .build_key, #extract_key, #serialize
    end

    it "raises on calls to ::build_key" do
      expect { IncompleteRepo.build_key }.to raise_error(NotImplementedError)
    end

    it "raises on calls to #extract_key" do
      expect { IncompleteRepo.new.extract_key }.to raise_error(NotImplementedError)
    end

    it "raises on calls to #serialize" do
      expect { IncompleteRepo.new.serialize }.to raise_error(NotImplementedError)
    end
  end

  describe '#bucket' do
    it 'delegates to .bucket' do
      b = double('bucket')
      ExampleRepo.should_receive(:bucket).and_return(b)
      expect(ExampleRepo.new.bucket).to eq(b)
    end
  end

end

end # Chibrary
