# frozen_string_literal: true

module Users
  class StatsPayload
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      rank = @user.rank

      {
        weekly_gr: WeeklyGrStats.call(user: @user),
        global_rank: GlobalRank.call(user: @user),
        win_rate: win_rate_percent(rank)
      }
    end

    private

    def win_rate_percent(rank)
      return unless rank
      return 0 if rank.matches_count.zero?

      ((rank.wins.to_f / rank.matches_count) * 100).round
    end
  end
end
