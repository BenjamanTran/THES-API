# frozen_string_literal: true

module Users
  class StatsPayload
    CACHE_TTL = 2.hours
    RACE_TTL = 10.seconds

    def self.call(user:)
      new(user: user).call
    end

    def self.bust_cache!(user_id)
      Rails.cache.delete("users/#{user_id}/stats/v2")
    end

    def initialize(user:)
      @user = user
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: RACE_TTL) do
        build_payload
      end
    end

    private

    def cache_key
      "users/#{@user.id}/stats/v2"
    end

    def build_payload
      rank = @user.rank

      {
        weekly_gr: WeeklyGrStats.call(user: @user),
        global_rank: GlobalRank.call(user: @user),
        win_rate: win_rate_percent(rank),
        favorite_venue: FavoriteVenue.call(user: @user)
      }
    end

    def win_rate_percent(rank)
      return unless rank
      return 0 if rank.matches_count.zero?

      ((rank.wins.to_f / rank.matches_count) * 100).round
    end
  end
end
