# frozen_string_literal: true

module Users
  module ActivityCache
    TIMELINE_KEY = 'users/%<user_id>s/activity_timeline/v1'
    TIMELINE_TTL = 10.minutes
    TIMELINE_RACE_TTL = 10.seconds

    module_function

    def bust_timeline!(user_id)
      Rails.cache.delete(format(TIMELINE_KEY, user_id: user_id))
    end
  end
end
