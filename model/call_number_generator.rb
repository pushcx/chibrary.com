require_relative 'call_number'
require_relative 'storage/redis_storage'

module CallNumberGenerator
  def self.next!
    raw = redis_next_call_number!
    call = to_base_62 raw
    CallNumber.new call
  end

  def self.redis_next_call_number!
    redis = RedisStorage.db_client
    loop do
      # clear any watch
      redis.unwatch
      # watch 'call_number' and fail the 'multi' call if it is modified
      # by another process
      redis.watch 'call_number'
      # grab the latest value
      last = redis.get('call_number').to_i
      # take the next one
      current = last + 1
      # try to commit the update
      success = redis.multi do |r|
        r.set('call_number', current)
      end
      # return it on success
      return current if success
      # random wait on failure to 
      sleep 0.1 + rand
    end
  ensure
    redis.unwatch
  end

  def self.to_base_62 i
    raise "No negative numbers" if i < 0

    chars = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a
    str = ""
    current = i

    while current != 0
      str = chars[current % 62].to_s + str
      current = current / 62
    end
    raise "Too-large int converted (#{i} -> #{str})" if str.length > 10
    ("%10s" % str).tr(' ', '0')
  end
end
