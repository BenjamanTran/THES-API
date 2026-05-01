class Game < ApplicationRecord
  has_many :game_participations, dependent: :destroy
  has_many :users, through: :game_participations

  TIERS = Rank.tiers

  enum :status, { pending: 0, ongoing: 1, finished: 2 }
  enum :match_type, { singles: 0, doubles: 1 }
  enum :min_tier, TIERS, prefix: true
  enum :max_tier, TIERS, prefix: true

  validates :status, presence: true
  validates :match_type, presence: true
  validate :tier_range_valid

  private

  def tier_range_valid
    return if min_tier || max_tier

    if TIERS[min_tier] > TIERS[max_tier]
      errors.add(:min_tier, "must be less than or equal to max_tier")
    end
  end
end
