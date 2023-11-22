module PromotionJobTracker
  def self.redis
    $redis
  end

  def self.job_enqueued(channel_key)
    $redis.incr("promotion_#{channel_key}_jobs_enqueued")
  end

  def self.job_completed(channel_key)
    $redis.incr("promotion_#{channel_key}_jobs_completed")
    check_completion(channel_key)
  end

  def self.check_completion(channel_key)
    enqueued = enqueued_jobs_count(channel_key)
    completed = completed_jobs_count(channel_key)

    if enqueued == completed
      notify_completion(channel_key)
      $redis.del("promotion_#{channel_key}_jobs_enqueued")
      $redis.del("promotion_#{channel_key}_jobs_completed")
    end
  end

  def self.notify_completion(channel_key)
    puts "-------- self.notify_completion--------------"
    ActionCable.server.broadcast(
      "promotion_notification:#{channel_key}",
      { status: 'completed'}
    )
  end

  def self.enqueued_jobs_count(channel_key)
    $redis.get("promotion_#{channel_key}_jobs_enqueued").to_i
  end

  def self.completed_jobs_count(channel_key)
    $redis.get("promotion_#{channel_key}_jobs_completed").to_i
  end
end
