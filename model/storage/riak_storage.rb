require 'riak'

$riak_client = Riak::Client.new(:protocol => "pbc", :pb_port => 8087)

module RiakStorage
  def bucket
    name = self.class.name.split('Storage').first.downcase
    @bucket ||= $riak_client.bucket(name)
  end
end
