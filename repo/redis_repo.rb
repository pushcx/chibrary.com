require 'redis'

module Chibrary

module RedisRepo
  def self.db_client
    $redis_client ||= Redis.new
  end
end

end # Chibrary
