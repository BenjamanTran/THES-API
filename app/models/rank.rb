# frozen_string_literal: true

class Rank < ApplicationRecord
  belongs_to :user

  enum :tier, {
    newbie: 0, beginner_plus: 1, lower_intermediate: 2,
    intermediate: 3, upper_intermediate: 4, advanced: 5,
    semi_pro: 6, professional: 7
  }

  validates :user_id, uniqueness: true
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :division, inclusion: { in: 1..3 }, allow_nil: true

  # 1★ = tier base; each star +100; 5★ = base+400; +100 promotion → next tier 1★ at base+500.
  STAR_STEP = 100
  STAR_SPAN = STAR_STEP * 4 # 1★→5★ = 400 pts (4 steps)
  TIER_SPAN = 500 # distance between 1★ of consecutive tiers (400 stars + 100 promotion)

  TIER_BASE = tiers.keys.map(&:to_sym).each_with_index.to_h { |tier, i| [tier, i * TIER_SPAN] }.freeze

  RATING_TIERS = TIER_BASE.map do |tier, base|
    [(base...(base + TIER_SPAN)), tier]
  end.to_h.freeze

  TIER_RANGES = TIER_BASE.transform_values { |base| [base, base + STAR_SPAN] }.freeze

  def display_name
    tier_name = I18n.t("ranks.#{tier}")
    return tier_name if division.nil?

    "#{tier_name} #{roman(division)}"
  end

  def update_tier_from_rating!
    new_tier = self.class.tier_for(rating)
    new_division = new_tier == :professional ? nil : division
    update!(tier: new_tier, division: new_division)
  end

  def self.tier_for(rating)
    rating = rating.to_i
    RATING_TIERS.each do |range, tier|
      return tier if range.cover?(rating)
    end
    :professional
  end

  def self.rating_from_tier_and_stars(tier_key, stars)
    stars = [[stars.to_i, 1].max, 5].min
    base = TIER_BASE[tier_key.to_sym] || 0
    base + ((stars - 1) * STAR_STEP)
  end

  def self.stars_for_rating(tier_key, rating)
    base = TIER_BASE[tier_key.to_sym] || 0
    offset = [rating.to_i - base, 0].max
    [[(offset / STAR_STEP) + 1, 1].max, 5].min
  end

  private

  def roman(number)
    { 1 => 'I', 2 => 'II', 3 => 'III' }[number]
  end
end
