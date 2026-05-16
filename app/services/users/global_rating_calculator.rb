# frozen_string_literal: true

module Users
  class GlobalRatingCalculator
    DEFAULT_BASE_RATING = 1000
    MATCH_WIN_POINTS = 10
    MATCH_LOSS_POINTS = 7

    def self.call(user:)
      new(user: user).call
    end

    def self.sync!(user:)
      new(user: user).sync!
    end

    def initialize(user:)
      @user = user
    end

    def call
      rank = @user.rank
      host_ratings = host_rated_participations
      host_count = host_ratings.size
      host_base = host_count.positive? ? average_host_base_rating(host_ratings) : DEFAULT_BASE_RATING
      match_points = match_points_delta(rank)
      rating = [host_base + match_points, 0].max
      tier = Rank.tier_for(rating).to_s

      {
        rating: rating,
        tier: tier,
        division: nil,
        display_name: I18n.t("ranks.#{tier}"),
        host_rating_count: host_count,
        host_base_rating: host_count.positive? ? host_base.round : nil,
        match_points: match_points
      }
    end

    def sync!
      rank = @user.rank || @user.create_rank!(tier: :newbie, rating: DEFAULT_BASE_RATING)
      data = call
      rank.update!(rating: data[:rating], tier: data[:tier], division: nil)
      data
    end

    private

    def host_rated_participations
      GameParticipation
        .where(user_id: @user.id)
        .where.not(host_rated_tier: nil)
        .where.not(host_rated_stars: nil)
    end

    def average_host_base_rating(participations)
      ratings = participations.filter_map do |gp|
        tier_key = gp.host_rated_tier_key&.to_sym
        next unless tier_key && Rank.tiers.key?(tier_key.to_s)

        Rank.rating_from_tier_and_stars(tier_key, gp.host_rated_stars)
      end
      return DEFAULT_BASE_RATING if ratings.empty?

      ratings.sum.to_f / ratings.size
    end

    def match_points_delta(rank)
      return 0 unless rank

      (rank.wins * MATCH_WIN_POINTS) - (rank.losses * MATCH_LOSS_POINTS)
    end
  end
end
