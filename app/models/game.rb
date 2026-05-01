# frozen_string_literal: true

class Game < ApplicationRecord
  has_many :game_participations, dependent: :destroy
  has_many :users, through: :game_participations
  belongs_to :host, class_name: 'User', optional: true

  TIERS = Rank.tiers

  enum :status, { open: 0, full: 1, ongoing: 2, finished: 3, cancelled: 4 }
  enum :match_type, { singles: 0, doubles: 1 }
  enum :min_tier, TIERS, prefix: true
  enum :max_tier, TIERS, prefix: true

  validates :status, presence: true
  validates :match_type, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :max_players, presence: true, inclusion: { in: [2, 4] }
  validate :tier_range_valid
  validate :time_range_valid
  validate :max_players_matches_match_type

  private

  def tier_range_valid
    return unless min_tier && max_tier
    return if TIERS[min_tier].to_i <= TIERS[max_tier].to_i

    errors.add(:min_tier, 'must be less than or equal to max_tier')
  end

  def time_range_valid
    return unless start_time && end_time

    errors.add(:start_time, 'must be before end_time') if start_time >= end_time
    errors.add(:start_time, 'must be in the future') if start_time <= Time.current
  end

  def max_players_matches_match_type
    return unless match_type && max_players

    expected = singles? ? 2 : 4
    return if max_players == expected

    errors.add(:max_players, "must be #{expected} for #{match_type}")
  end
end
