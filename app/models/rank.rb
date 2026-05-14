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

  RATING_TIERS = {
    0..399 => :newbie,
    400..799 => :beginner_plus,
    800..1199 => :lower_intermediate,
    1200..1499 => :intermediate,
    1500..1799 => :upper_intermediate,
    1800..2099 => :advanced,
    2100..2399 => :semi_pro,
    2400.. => :professional
  }.freeze

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
    RATING_TIERS.find { |range, _| range.cover?(rating) }&.last || :newbie
  end

  TIER_RANGES = {
    newbie: [0, 399], beginner_plus: [400, 799], lower_intermediate: [800, 1199],
    intermediate: [1200, 1499], upper_intermediate: [1500, 1799], advanced: [1800, 2099],
    semi_pro: [2100, 2399], professional: [2400, 2800]
  }.freeze

  def self.rating_from_tier_and_stars(tier_key, stars)
    stars = [[stars.to_i, 1].max, 5].min
    bounds = TIER_RANGES[tier_key.to_sym] || [0, 399]
    low, high = bounds
    low + ((stars - 1) * (high - low) / 4.0).round
  end

  private

  def roman(number)
    { 1 => 'I', 2 => 'II', 3 => 'III' }[number]
  end
end
