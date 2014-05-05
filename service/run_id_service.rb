require_relative '../repo/redis_repo'

class RunIdService
  def run_id
    @run_id ||= next!
  end

  def next!
    @run_id = redis_next_run_id!
  end

  def redis_next_run_id!
    redis = RedisRepo.db_client
    loop do
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
      redis.unwatch and return current if success
      # random wait on failure to get out of sync with other attempts
      sleep 0.01 + rand / 10
    end
  end


end
