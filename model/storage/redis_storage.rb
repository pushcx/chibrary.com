require 'redis'

module RedisStorage
  def self.db_client
    $redis_client ||= Redis.new
  end
end
