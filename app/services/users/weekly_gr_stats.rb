# frozen_string_literal: true

module Users
  class WeeklyGrStats
    WIN_POINTS = 10
    LOSS_POINTS = 7
    TIME_ZONE = 'Asia/Ho_Chi_Minh'

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      scope = weekly_scored_participations
      wins = scope.where(winner: true).count
      losses = scope.where(winner: false).count

      {
        delta: (wins * WIN_POINTS) - (losses * LOSS_POINTS),
        wins: wins,
        losses: losses,
        matches: wins + losses,
        win_points: WIN_POINTS,
        loss_points: LOSS_POINTS
      }
    end

    private

    def weekly_scored_participations
      range = week_range

      MatchParticipation
        .joins(:match)
        .where(user_id: @user.id)
        .merge(
          Match.finished
            .where(finished_at: range)
            .where.not(winner_team: nil)
        )
    end

    def week_range
      zone = ActiveSupport::TimeZone[TIME_ZONE]
      now = zone.now
      now.beginning_of_week..now.end_of_week
    end
  end
end
