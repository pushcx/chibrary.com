require 'redis'

module RedisRepo
  def self.db_client
    $redis_client ||= Redis.new
  end
end
