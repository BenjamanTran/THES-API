# frozen_string_literal: true

module Users
  class AchievementsList
    CACHE_TTL = 2.hours
    RACE_TTL = 10.seconds
    WIN_RATE_MIN_MATCHES = 20
    WIN_RATE_THRESHOLD = 70

    def self.call(user:)
      new(user: user).call
    end

    def self.bust_cache!(user_id)
      Rails.cache.delete("users/#{user_id}/achievements/v1")
    end

    def initialize(user:)
      @user = user
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: RACE_TTL) do
        build_list
      end
    end

    private

    def cache_key
      "users/#{@user.id}/achievements/v1"
    end

    def build_list
      ctx = build_context
      definitions.map { |defn| build_achievement(defn, ctx) }
    end

    def build_context
      rank = @user.rank
      weekly = WeeklyGrStats.call(user: @user)
      global_rank = GlobalRank.call(user: @user)
      participation_stats = game_participation_stats

      {
        matches_count: rank&.matches_count.to_i,
        wins: rank&.wins.to_i,
        losses: rank&.losses.to_i,
        play_time_seconds: rank&.play_time_seconds.to_i,
        games_joined: participation_stats[:joined],
        host_ratings_count: participation_stats[:host_rated],
        global_rank: global_rank,
        weekly_matches: weekly[:matches],
        weekly_delta: weekly[:delta],
        max_win_streak: compute_max_win_streak,
        tier: rank&.tier&.to_s,
        win_rate: win_rate_percent(rank)
      }
    end

    def definitions
      [
        { id: 'first_match', name: 'Người mới', icon: '🌱', target: 1, current: :matches_count },
        { id: 'matches_10', name: '10 trận', icon: '🏸', target: 10, current: :matches_count },
        { id: 'matches_50', name: '50 trận', icon: '🎯', target: 50, current: :matches_count },
        { id: 'matches_100', name: '100 trận', icon: '🏆', target: 100, current: :matches_count },
        { id: 'first_win', name: 'Thắng đầu', icon: '✨', target: 1, current: :wins },
        { id: 'wins_25', name: '25 thắng', icon: '💪', target: 25, current: :wins },
        { id: 'streak_3', name: 'Chuỗi 3', icon: '🔥', target: 3, current: :max_win_streak },
        { id: 'streak_5', name: 'Chuỗi 5', icon: '🔥', target: 5, current: :max_win_streak },
        { id: 'streak_10', name: 'Chuỗi 10', icon: '💎', target: 10, current: :max_win_streak },
        { id: 'play_10h', name: '10 giờ', icon: '⏱️', target: 36_000, current: :play_time_seconds },
        { id: 'play_50h', name: '50 giờ', icon: '⏱️', target: 180_000, current: :play_time_seconds },
        { id: 'games_5', name: '5 buổi', icon: '📅', target: 5, current: :games_joined },
        { id: 'top_100', name: 'Top 100', icon: '👑', target: 100, current: :global_rank, rank_ceiling: true },
        { id: 'weekly_5', name: 'Tuần 5 trận', icon: '⚡', target: 5, current: :weekly_matches },
        { id: 'host_rated_3', name: 'Host tin', icon: '⭐', target: 3, current: :host_ratings_count },
        { id: 'win_rate_70', name: 'Tỷ lệ 70%', icon: '📈', check: :win_rate_70_unlocked }
      ]
    end

    def build_achievement(defn, ctx)
      if defn[:check] == :win_rate_70_unlocked
        unlocked = win_rate_70_unlocked?(ctx)
        progress = unlocked ? nil : { current: ctx[:win_rate], target: WIN_RATE_THRESHOLD }
      elsif defn[:rank_ceiling]
        rank = ctx[:global_rank]
        unlocked = rank.present? && rank <= defn[:target]
        progress = rank.present? ? { current: rank, target: defn[:target] } : { current: 0, target: defn[:target] }
      else
        current = ctx[defn[:current]].to_i
        target = defn[:target]
        unlocked = current >= target
        progress = unlocked ? nil : { current: current, target: target }
      end

      {
        id: defn[:id],
        name: defn[:name],
        icon: defn[:icon],
        unlocked: unlocked,
        progress: progress
      }
    end

    def win_rate_70_unlocked?(ctx)
      ctx[:matches_count] >= WIN_RATE_MIN_MATCHES && ctx[:win_rate] >= WIN_RATE_THRESHOLD
    end

    def win_rate_percent(rank)
      return 0 unless rank
      return 0 if rank.matches_count.zero?

      ((rank.wins.to_f / rank.matches_count) * 100).round
    end

    def compute_max_win_streak
      results = scored_participations_ordered_asc.pluck(:winner)
      return 0 if results.empty?

      max_streak = 0
      current = 0
      results.each do |won|
        if won
          current += 1
          max_streak = current if current > max_streak
        else
          current = 0
        end
      end
      max_streak
    end

    def game_participation_stats
      row = GameParticipation
            .where(user_id: @user.id)
            .pick(
              Arel.sql('COUNT(*)'),
              Arel.sql('SUM(CASE WHEN host_rated_tier IS NOT NULL THEN 1 ELSE 0 END)')
            )
      { joined: row[0].to_i, host_rated: row[1].to_i }
    end

    def scored_participations_ordered_asc
      MatchParticipation
        .joins(:match)
        .where(user_id: @user.id)
        .merge(Match.finished.where.not(winner_team: nil).where.not(finished_at: nil))
        .order('matches.finished_at ASC')
    end
  end
end
