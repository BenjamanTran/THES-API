# frozen_string_literal: true

class UserSkillSnapshot < ApplicationRecord
  AXES = %i[
    attack
    defense
    technique
    agility
    footwork
    stamina
  ].freeze

  belongs_to :user

  validates :month, presence: true
  validates :user_id, uniqueness: { scope: :month }
  validates :declared_tier, presence: true, inclusion: { in: Rank.tiers.values }
  validates :computed_stars, presence: true, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 5 }
  validates :declared_rating, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates(*AXES, presence: true, inclusion: { in: 1..10 })
  validates :overall_score, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  before_validation :normalize_month
  before_validation :calculate_overall_score
  before_validation :calculate_declared_rating

  def self.upsert_for_month!(user:, tier:, scores:, month: Date.current)
    validate_score_presence!(scores)
    snapshot = user.skill_snapshots.find_or_initialize_by(month: month.to_date.beginning_of_month)
    tier_key = normalize_tier!(tier)
    snapshot.assign_attributes(scores.slice(*AXES).merge(declared_tier: Rank.tiers.fetch(tier_key)))

    transaction do
      snapshot.save!
      snapshot.apply_declared_rank!
    end

    snapshot
  end

  def apply_declared_rank!
    tier_key = declared_tier_key
    rank = user.rank || user.build_rank

    rank.assign_attributes(
      declared_tier: Rank.tiers[tier_key.to_s],
      declared_rating: declared_rating,
      tier: tier_key,
      rating: declared_rating,
      division: tier_key == :professional ? nil : 3
    )
    rank.save!
  end

  def self.computed_stars_from_overall(score)
    [[(score.to_f / 2.0).round(2), 0.5].max, 5].min
  end

  def scores
    AXES.index_with { |axis| public_send(axis) }
  end

  def declared_tier_key
    Rank.tiers.key(declared_tier)
  end

  def self.normalize_tier!(tier)
    tier_key = tier.to_s
    raise ArgumentError, 'Trình độ không hợp lệ' unless Rank.tiers.key?(tier_key)

    tier_key
  end

  def self.validate_score_presence!(scores)
    missing_axis = (AXES - scores.keys.map(&:to_sym)).first
    raise ArgumentError, "#{missing_axis.to_s.humanize} is required" if missing_axis
  end

  private

  def normalize_month
    self.month = month.to_date.beginning_of_month if month.present?
  end

  def calculate_overall_score
    return unless AXES.all? { |axis| public_send(axis).present? }

    self.overall_score = (AXES.sum { |axis| public_send(axis).to_f } / AXES.length).round(1)
  end

  def calculate_declared_rating
    return if overall_score.blank? || declared_tier.blank?

    self.computed_stars = self.class.computed_stars_from_overall(overall_score)
    base = Rank::TIER_BASE[declared_tier_key.to_sym] || 0
    self.declared_rating = (base + ((computed_stars.to_f - 1) * Rank::STAR_STEP)).round
  end
end
