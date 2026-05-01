# frozen_string_literal: true

class Rank < ApplicationRecord
  belongs_to :user

  enum :tier, { bronze: 0, silver: 1, gold: 2, platinum: 3, diamond: 4, master: 5 }

  validates :user_id, uniqueness: true
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :division, inclusion: { in: 1..3 }, allow_nil: true

  RATING_TIERS = {
    0..799 => :bronze,
    800..1199 => :silver,
    1200..1599 => :gold,
    1600..1999 => :platinum,
    2000..2499 => :diamond,
    2500.. => :master
  }.freeze

  def display_name
    tier_name = I18n.t("ranks.#{tier}")
    return tier_name if division.nil?

    "#{tier_name} #{roman(division)}"
  end

  def update_tier_from_rating!
    new_tier = self.class.tier_for(rating)
    new_division = new_tier == :master ? nil : division
    update!(tier: new_tier, division: new_division)
  end

  def self.tier_for(rating)
    RATING_TIERS.find { |range, _| range.cover?(rating) }&.last || :bronze
  end

  private

  def roman(number)
    { 1 => 'I', 2 => 'II', 3 => 'III' }[number]
  end
end
