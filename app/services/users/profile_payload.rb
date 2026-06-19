# frozen_string_literal: true

module Users
  class ProfilePayload
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      activity = RecentActivityFeed.call(user: @user, limit: RecentActivityFeed::PROFILE_LIMIT, offset: 0)

      {
        achievements: AchievementsList.call(user: @user),
        recent_activity: activity[:recent_activity],
        recent_activity_has_more: activity[:has_more]
      }.merge(SkillProfilePayload.call(user: @user))
    end
  end
end
