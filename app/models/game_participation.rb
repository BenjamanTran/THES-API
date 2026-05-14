# frozen_string_literal: true

class GameParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :team, { team_a: 0, team_b: 1 }
  enum :role, { player: 0, co_host: 1 }
  enum :host_rated_tier, {
    hr_newbie: 0, hr_beginner_plus: 1, hr_lower_intermediate: 2,
    hr_intermediate: 3, hr_upper_intermediate: 4, hr_advanced: 5,
    hr_semi_pro: 6, hr_professional: 7
  }, prefix: :host_rated

  validates :team, presence: true
  validates :user_id, uniqueness: { scope: :game_id }
  validates :host_rated_stars, inclusion: { in: 1..5 }, allow_nil: true
  validates :host_rating_note, length: { maximum: 200 }, allow_nil: true
  validate :max_co_hosts, if: :co_host?

  HOST_TIER_MAP = {
    'newbie' => :hr_newbie, 'beginner_plus' => :hr_beginner_plus,
    'lower_intermediate' => :hr_lower_intermediate, 'intermediate' => :hr_intermediate,
    'upper_intermediate' => :hr_upper_intermediate, 'advanced' => :hr_advanced,
    'semi_pro' => :hr_semi_pro, 'professional' => :hr_professional
  }.freeze

  REVERSE_TIER_MAP = HOST_TIER_MAP.invert.transform_values(&:to_s).freeze

  def host_rated_tier_key
    REVERSE_TIER_MAP[host_rated_tier&.to_sym]
  end

  private

  def max_co_hosts
    count = game.game_participations.co_host.where.not(id: id).count
    errors.add(:role, 'maximum 3 co-hosts per game') if count >= 3
  end
end
