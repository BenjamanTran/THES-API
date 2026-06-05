# frozen_string_literal: true

class Game < ApplicationRecord
  include GameSearchable if Rails.application.config.x.elasticsearch_enabled

  has_many :game_participations, dependent: :destroy
  has_many :users, through: :game_participations
  has_many :game_player_pairs, dependent: :destroy
  has_many :matches, dependent: :destroy
  belongs_to :host, class_name: 'User', optional: true
  belongs_to :venue, optional: true

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
  # Mine / upcoming list: live sessions before scheduled, then by start time.
  scope :order_active_first, lambda {
    order(
      Arel.sql(<<~SQL.squish),
        CASE games.status
          WHEN #{statuses[:ongoing]} THEN 0
          WHEN #{statuses[:open]} THEN 1
          WHEN #{statuses[:full]} THEN 2
          ELSE 3
        END ASC
      SQL
      start_time: :asc
    )
  }

  scope :hosted_or_joined_by, lambda { |user|
    left_joins(:game_participations)
      .where('games.host_id = :uid OR game_participations.user_id = :uid', uid: user.id)
      .distinct
  }

  scope :managed_by, lambda { |user|
    co_host = GameParticipation.roles[:co_host]
    where(
      <<~SQL.squish,
        games.host_id = :uid OR EXISTS (
          SELECT 1 FROM game_participations gp
          WHERE gp.game_id = games.id AND gp.user_id = :uid AND gp.role = :co_host
        )
      SQL
      uid: user.id, co_host: co_host
    )
  }

  scope :manage_session_active, lambda {
    ongoing_game = statuses[:ongoing]
    ongoing_match = Match.statuses[:ongoing]
    where.not(status: %i[finished cancelled])
         .where(end_time: Time.current..)
         .where(
           <<~SQL.squish,
             games.status = :ongoing_game OR EXISTS (
               SELECT 1 FROM matches m
               WHERE m.game_id = games.id AND m.status = :ongoing_match
             )
           SQL
           ongoing_game: ongoing_game, ongoing_match: ongoing_match
         )
  }

  before_create :generate_invite_code, :generate_edit_token

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

  def valid_edit_token?(token)
    token.present? && edit_token.present? &&
      ActiveSupport::SecurityUtils.secure_compare(edit_token, token.to_s)
  end

  def can_manage?(user: nil, edit_token: nil)
    return true if valid_edit_token?(edit_token)
    return false unless user

    host_or_co_host?(user)
  end

  def host_or_co_host?(user)
    return false unless user

    return true if host_id == user.id

    game_participations.co_host.exists?(user_id: user.id)
  end

  def within_play_time?(at: Time.current)
    return false if cancelled? || finished?
    return true if ongoing?

    at >= start_time && at <= end_time
  end

  def session_started?
    ongoing? ||
      Time.current >= start_time ||
      matches.where(status: %i[ongoing pending]).exists?
  end

  # Invite link: live only when a match is actively being played.
  def invite_play_live?
    matches.where(status: :ongoing).exists?
  end

  def spectator_viewable?
    !finished? && !cancelled? && invite_play_live?
  end

  def active_player_pairs
    game_player_pairs.active_pairs
  end

  def configured_court_count
    list = Array(courts).map(&:to_i).select(&:positive?).uniq
    [list.length, 1].max
  end

  def pending_queue_full?
    matches.pending.count >= configured_court_count
  end

  # At least one registered pair can still play a pair-arranged match (per-pair quota).
  def can_arrange_pair_match?
    return false unless doubles?

    pairs = active_player_pairs
    return false if pairs.empty?
    return true if pair_matches_limit.nil?

    pairs.any? { |p| !p.at_pair_match_limit?(self) }
  end

  # Scheduled window length (host start_time → end_time), used for play-time stats.
  def duration_seconds
    return 0 unless start_time && end_time

    [(end_time - start_time).to_i, 0].max
  end

  def valid_invite_code?(code)
    code.present? && invite_code.present? &&
      ActiveSupport::SecurityUtils.secure_compare(invite_code, code.to_s)
  end

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

  def generate_invite_code
    self.invite_code ||=
      loop do
        code = SecureRandom.alphanumeric(8).downcase
        break code unless Game.exists?(invite_code: code)
      end
  end

  def generate_edit_token
    self.edit_token ||=
      loop do
        token = SecureRandom.urlsafe_base64(24)
        break token unless Game.exists?(edit_token: token)
      end
  end
end
