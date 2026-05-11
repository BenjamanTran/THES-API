# frozen_string_literal: true

class Game < ApplicationRecord
  include GameSearchable if Rails.application.config.x.elasticsearch_enabled

  has_many :game_participations, dependent: :destroy
  has_many :users, through: :game_participations
  belongs_to :host, class_name: 'User', optional: true

  TIERS = Rank.tiers

  enum :status, { open: 0, full: 1, ongoing: 2, finished: 3, cancelled: 4 }
  enum :match_type, { singles: 0, doubles: 1 }
  enum :min_tier, TIERS, prefix: true
  enum :max_tier, TIERS, prefix: true

  scope :upcoming, -> { where(end_time: Time.current..) }
  scope :past, -> { where(end_time: ...Time.current) }
  scope :by_time, ->(t) { t.to_s == 'past' ? past : upcoming }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_time_from, ->(time) { where(start_time: time..) if time.present? }
  scope :by_time_to, ->(time) { where(start_time: ..time) if time.present? }
  scope :by_tier, lambda { |tier|
    return unless tier.present? && TIERS.key?(tier)

    tier_val = TIERS[tier]
    where('min_tier <= ? AND max_tier >= ?', tier_val, tier_val)
  }
  scope :hosted_or_joined_by, lambda { |user|
    left_joins(:game_participations)
      .where('games.host_id = :uid OR game_participations.user_id = :uid', uid: user.id)
      .distinct
  }

  validates :status, presence: true
  validates :match_type, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :max_players, presence: true, numericality: { greater_than_or_equal_to: 2 }
  validates :min_price, numericality: { greater_than_or_equal_to: 0 }
  validates :max_price, numericality: { greater_than_or_equal_to: 0 }
  validate :tier_range_valid
  validate :time_range_valid
  validate :price_range_valid

  def fit_level(user)
    return unless user&.rank

    user_tier = TIERS[user.rank.tier] || 0
    min_val = TIERS[min_tier] || 0
    max_val = TIERS[max_tier] || 0

    if user_tier.between?(min_val, max_val)
      'good'
    elsif (user_tier - min_val).abs <= 1 || (user_tier - max_val).abs <= 1
      'warning'
    else
      'hard'
    end
  end

  private

  def tier_range_valid
    return unless min_tier && max_tier
    return if TIERS[min_tier].to_i <= TIERS[max_tier].to_i

    errors.add(:min_tier, 'must be less than or equal to max_tier')
  end

  def time_range_valid
    return unless start_time && end_time

    errors.add(:start_time, 'must be before end_time') if start_time >= end_time
    return unless start_time_changed? && start_time <= Time.current

    errors.add(:start_time, 'must be in the future')
  end

  def price_range_valid
    return unless min_price && max_price
    return if min_price <= max_price

    errors.add(:min_price, 'must be less than or equal to max_price')
  end

end
