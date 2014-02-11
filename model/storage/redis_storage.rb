module RedisStorage
  def db_client
    $redis_client ||= Redis.new
  end
end
