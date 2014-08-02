require_relative '../rspec'
require_relative '../../service/run_id_service'

module Chibrary

describe RunIdService do
  describe "#run_id" do
    it "accesses @run_id" do
      ris = RunIdService.new
      ris.instance_variable_set(:@run_id, 2)
      expect(ris.run_id).to eq(2)
    end
  end

  describe "#next! command" do
    it "sends command to hit redis" do
      ris = RunIdService.new
      ris.should_receive(:redis_consume_run_id!)
      ris.next!
    end
  end

  describe "#redis_consume_run_id!" do
    # This is a very brittle test, but there's no way to test-and-set with
    # Redis than this sequence of commands.
    it 'uses a redis watch to guard against duplicate use' do
      redis = double('redis')
      redis.should_receive(:unwatch) # to clear watches
      redis.should_receive(:watch).with('run_id') # to watch run_id
      redis.should_receive(:get).with('run_id').and_return(0) # to get it
      redis.should_receive(:multi).and_yield(redis).and_return(true) # into block
      redis.should_receive(:set).with('run_id', 1) # increments run_id
      redis.should_receive(:unwatch).and_return(true) # is happy and done
      RedisRepo.should_receive(:db_client).and_return(redis)
      ris = RunIdService.new
      expect(ris.send(:redis_consume_run_id!)).to eq(0)
    end

    it 'gives up after many collisions' do
      redis = double('redis', unwatch: true, watch: true, get: 1, multi: false)
      RedisRepo.should_receive(:db_client).and_return(redis)
      ris = RunIdService.new
      ris.stub(:sleep)
      expect {
        ris.send(:redis_consume_run_id!)
      }.to raise_error(TooManyRunCollisions)
    end
  end
end

end # Chibrary
