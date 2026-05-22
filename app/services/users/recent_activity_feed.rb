# frozen_string_literal: true

module Users
  class RecentActivityFeed
    PROFILE_LIMIT = 5
    PAGE_LIMIT = 20
    MAX_PAGE_LIMIT = 50
    TIMELINE_CAP = 500
    PREVIEW_MATCH_FETCH = 12
    PREVIEW_JOIN_FETCH = 8

    def self.call(user:, limit: PROFILE_LIMIT, offset: 0)
      new(user: user, limit: limit, offset: offset).call
    end

    def initialize(user:, limit:, offset: 0)
      @user = user
      @limit = [[limit.to_i, 1].max, MAX_PAGE_LIMIT].min
      @offset = [offset.to_i, 0].max
    end

    def call
      if @offset.zero? && @limit <= PROFILE_LIMIT
        return preview_response
      end

      paginate(merged_timeline)
    end

    private

    def preview_response
      timeline = (match_items(PREVIEW_MATCH_FETCH) + join_items(PREVIEW_JOIN_FETCH))
                   .sort_by { |i| i[:occurred_at] }
                   .reverse
      page = timeline.first(@limit)

      {
        recent_activity: page,
        has_more: preview_has_more?(timeline),
        next_offset: page.length
      }
    end

    def preview_has_more?(timeline)
      return true if timeline.length > @limit

      finished_matches = MatchParticipation
                           .joins(:match)
                           .where(user_id: @user.id)
                           .merge(Match.finished.where.not(winner_team: nil).where.not(finished_at: nil))
                           .count
      joins = GameParticipation.where(user_id: @user.id).count
      finished_matches + joins > @limit
    end

    def paginate(timeline)
      page = timeline.drop(@offset).first(@limit)
      next_offset = @offset + page.length

      {
        recent_activity: page,
        has_more: next_offset < timeline.length,
        next_offset: next_offset
      }
    end

    def merged_timeline
      Rails.cache.fetch(
        format(ActivityCache::TIMELINE_KEY, user_id: @user.id),
        expires_in: ActivityCache::TIMELINE_TTL,
        race_condition_ttl: ActivityCache::TIMELINE_RACE_TTL
      ) do
        build_full_timeline
      end
    end

    def build_full_timeline
      (match_items(TIMELINE_CAP) + join_items(200))
        .sort_by { |i| i[:occurred_at] }
        .reverse
    end

    def match_items(fetch_limit)
      participations = MatchParticipation
                         .joins(match: :game)
                         .includes(match: { match_participations: :user, game: :venue })
                         .where(user_id: @user.id)
                         .merge(Match.finished.where.not(winner_team: nil).where.not(finished_at: nil))
                         .order('matches.finished_at DESC')
                         .limit(fetch_limit)

      participations.map { |mp| match_item(mp) }
    end

    def match_item(mp)
      match = mp.match
      won = mp.winner?
      win_pts = GlobalRatingCalculator::MATCH_WIN_POINTS
      loss_pts = GlobalRatingCalculator::MATCH_LOSS_POINTS

      {
        type: won ? 'match_win' : 'match_loss',
        title: "#{won ? 'Thắng' : 'Thua'} vs #{opponent_label(match, mp)}",
        subtitle: game_subtitle(match.game),
        gr_delta: won ? win_pts : -loss_pts,
        occurred_at: match.finished_at.iso8601,
        game_id: match.game_id
      }
    end

    def join_items(fetch_limit)
      GameParticipation
        .joins(:game)
        .includes(game: :venue)
        .where(user_id: @user.id)
        .order(created_at: :desc)
        .limit(fetch_limit)
        .map { |gp| join_item(gp) }
    end

    def join_item(gp)
      game = gp.game
      {
        type: 'game_join',
        title: 'Tham gia buổi chơi',
        subtitle: game_subtitle(game),
        gr_delta: nil,
        occurred_at: gp.created_at.iso8601,
        game_id: game.id
      }
    end

    def opponent_label(match, participation)
      opponents = match.match_participations.reject { |p| p.user_id == participation.user_id }
      names = opponents.map { |p| p.user.name.presence || 'Đối thủ' }.uniq
      return 'Đối thủ' if names.empty?

      names.size > 2 ? "#{names.first} & #{names.size - 1} người" : names.join(' & ')
    end

    def game_subtitle(game)
      game.venue&.name.presence || game.location.presence || game.title.presence
    end
  end
end
