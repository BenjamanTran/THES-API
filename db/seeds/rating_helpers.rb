# frozen_string_literal: true

# Aligns with Rank model + FE lib/rating-stars.ts:
#   tier base = tier_index × 500
#   stars 1–5 → base + (stars − 1) × 100
# Global rating (API display) = avg(host-rated base) + wins×10 − losses×7
#   (defaults to 200 when no host rating on participations)

module Seeds
  module RatingHelpers
    module_function

    def upsert_player_rank!(user, tier:, stars: 3, wins: 0, losses: 0, now: Time.current)
      tier = tier.to_sym
      stars = [[stars.to_i, 1].max, 5].min
      rating = Rank.rating_from_tier_and_stars(tier, stars)
      played = wins + losses

      rank = Rank.find_or_initialize_by(user_id: user.id)
      rank.assign_attributes(
        tier: tier,
        rating: rating,
        declared_tier: Rank.tiers[tier],
        declared_rating: rating,
        division: nil,
        wins: wins,
        losses: losses,
        matches_count: played,
        last_played_at: played.positive? ? now : nil
      )
      rank.save!
      rank
    end

    def apply_host_skill!(participation, tier:, stars: 3)
      tier_key = tier.to_s
      map = GameParticipation::HOST_TIER_MAP
      raise ArgumentError, "Unknown tier: #{tier_key}" unless map.key?(tier_key)

      participation.update!(
        host_rated_tier: map[tier_key],
        host_rated_stars: [[stars.to_i, 1].max, 5].min
      )
    end

    def apply_host_skills_from_profiles!(profiles_by_email)
      GameParticipation.includes(:user).find_each do |gp|
        email = gp.user&.email
        next if email.blank?

        profile = profiles_by_email[email]
        next unless profile

        apply_host_skill!(gp, tier: profile[:tier], stars: profile[:stars])
      end
    end

    def sync_all_global_ratings!
      User.where(placeholder: false, guest: false).includes(:rank).find_each do |user|
        next unless user.rank

        Users::GlobalRatingCalculator.sync!(user: user)
      end
    end
  end
end
