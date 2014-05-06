require_relative '../rspec'
require_relative '../../repo/riak_bucket'

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
      b = double('Riak::Bucket', :"[]" => 'value')
      rb = RiakBucket.new b
      expect(rb['key']).to eq('value')
    end

    it "wraps Riak's exception to NotFound" do
      b = double('Riak::Bucket')
      b.should_receive(:[]).with('key').and_raise(Riak::ProtobuffsFailedRequest.new('a', 'b'))
      rb = RiakBucket.new b
      expect {
        rb['key']
      }.to raise_error(NotFound)
    end
  end
end
