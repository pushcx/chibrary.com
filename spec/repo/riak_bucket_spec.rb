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

  describe "#get_any" do
    it "fetches many values" do
      r = double('Riak::Result', data: { 'foo' => 'foo' })
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:get_many).with(['a', 'b']).and_return({ 'a' => r, 'b' => nil })
      rb = RiakBucket.new b
      results = rb.get_any ['a', 'b']
      expect(results).to be_a(Hash)
      expect(results.keys).to eq(['a', 'b'])
    end

    it "symbolizes keys in the values" do
      r = double('Riak::Result', data: { 'foo' => 'foo' })
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:get_many).with(['a']).and_return({ 'a' => r })
      rb = RiakBucket.new b
      results = rb.get_any ['a']
      expect(results['a'].keys.first).to be_a(Symbol)
    end

    it "returns nils to missing keys" do
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:get_many).with(['b']).and_return({ 'b' => nil })
      rb = RiakBucket.new b
      results = rb.get_any ['b']
      expect(results['b']).to eq(nil)
    end
  end

  describe "#get_all" do
    it "fetches many values" do
      r = double('Riak::Result', data: { 'foo' => 'foo' })
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:get_many).with(['a', 'b']).and_return({ 'a' => r, 'b' => r })
      rb = RiakBucket.new b
      results = rb.get_all ['a', 'b']
      expect(results).to be_a(Hash)
      expect(results.keys).to eq(['a', 'b'])
    end

    it "raises on missing keys" do
      b = double('Riak::Bucket', name: 'name')
      b.should_receive(:get_many).with(['a']).and_return({ 'a' => nil })
      rb = RiakBucket.new b
      expect {
        results = rb.get_all ['a']
      }.to raise_error(NotFound)
    end
  end
end

end # Chibrary
