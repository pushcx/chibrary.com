require_relative '../../rspec'
require_relative '../../../model/storage/riak_storage'

stored_riak_client = $riak_client
$riak_client = FakeStorage.new

describe RiakStorage do
  class ExampleStorage
    include RiakStorage
  end

  it 'gives the storage class a bucket named for the model' do
    expect(ExampleStorage.new.bucket.name).to eq('example')
  end
end

$riak_client = stored_riak_client
