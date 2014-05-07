require_relative '../repo/redis_repo'

class TooManyRunCollisions < RuntimeError ; end

class RunIdService
  def run_id
    @run_id ||= next!
  end

  def next!
    @run_id = redis_consume_run_id!
  end

  private

  def redis_consume_run_id!
    redis = RedisRepo.db_client
    attempts = 0
    loop do
      raise TooManyRunCollisions, "Too many attempts" if (attempts += 1) > 20

      # clear any watch
      redis.unwatch
      # watch 'call_number' and fail the 'multi' call if it is modified
      # by another process
      redis.watch 'run_id'
      # grab the latest value
      last = redis.get('run_id').to_i
      # take the next one
      current = last + 1
      # try to commit the update
      success = redis.multi do |r|
        r.set('run_id', current)
      end
      # return it on success
      redis.unwatch and return last if success
      # random wait on failure to get out of sync with other attempts
      sleep 0.01 + rand / 10
    end
  end
end
