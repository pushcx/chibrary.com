require_relative '../rspec'
require_relative '../../repo/riak_bucket'

module Chibrary

describe RiakBucket do
  describe "#initialize" do
    it "wraps a Riak Bucket object" do
      b = double('Riak::Bucket')
      rb = RiakBucket.new b
      expect(rb.instance_variable_get(:@bucket)).to eq(b)
    end
  end

  describe "#[]" do
    it "proxies to the bucket's []" do
      o = double('Riak::RObject', data: 'value')
      b = double('Riak::Bucket')
      b.should_receive(:[]).with('key').and_return(o)
      rb = RiakBucket.new b
      expect(rb['key']).to eq('value')
    end

    it "wraps Riak's exception to NotFound" do
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:[]).with('key').and_raise(Riak::ProtobuffsFailedRequest.new('a', 'b'))
      rb = RiakBucket.new b
      expect {
        rb['key']
      }.to raise_error(NotFound)
    end
  end

  describe "#[]=" do
    it "writes value" do
      o = double('Riak::RObject')
      b = double('Riak::Bucket')
      b.should_receive(:new).with('key').and_return(o)
      o.should_receive(:data=).with('value')
      o.should_receive(:store)
      rb = RiakBucket.new b
      rb['key'] = 'value'
    end
  end
end

end # Chibrary
