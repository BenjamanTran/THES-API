# frozen_string_literal: true

module Users
  module ProfileCache
    module_function

    def bust_for_user!(user_id)
      AchievementsList.bust_cache!(user_id)
      ActivityCache.bust_timeline!(user_id)
      StatsPayload.bust_cache!(user_id)
    end
  end
end
