# frozen_string_literal: true

class GamePlayerPair < ApplicationRecord
  belongs_to :game
  belongs_to :user_a, class_name: 'User'
  belongs_to :user_b, class_name: 'User'
  belongs_to :created_by, class_name: 'User', optional: true

  enum :status, { active: 0, dissolved: 1 }

  before_validation :normalize_user_order

  validates :user_a_id, presence: true
  validates :user_b_id, presence: true
  validate :users_are_distinct
  validate :users_in_game
  validate :users_not_in_other_active_pair, on: :create

  scope :active_pairs, -> { where(status: :active) }

  def self.normalize_ids(id_a, id_b)
    id_a = id_a.to_i
    id_b = id_b.to_i
    id_a < id_b ? [id_a, id_b] : [id_b, id_a]
  end

  def includes_user?(user_id)
    user_a_id == user_id || user_b_id == user_id
  end

  def at_pair_match_limit?(game)
    return false if game.pair_matches_limit.nil?

    matches_used >= game.pair_matches_limit
  end

  def pair_matches_remaining(game)
    return if game.pair_matches_limit.nil?

    [game.pair_matches_limit - matches_used, 0].max
  end

  private

  def normalize_user_order
    return unless user_a_id.present? && user_b_id.present?

    self.user_a_id, self.user_b_id = self.class.normalize_ids(user_a_id, user_b_id)
  end

  def users_are_distinct
    return unless user_a_id == user_b_id

    errors.add(:user_b_id, 'must be different from user_a')
  end

  def users_in_game
    return unless game_id && user_a_id && user_b_id

    participant_ids = game.game_participations.pluck(:user_id)
    missing = [user_a_id, user_b_id] - participant_ids
    return if missing.empty?

    errors.add(:base, "Players not in this game: #{missing.join(', ')}")
  end

  def users_not_in_other_active_pair
    return unless game_id && user_a_id && user_b_id

    scope = game.game_player_pairs.active_pairs
    scope = scope.where.not(id: id) if persisted?
    [user_a_id, user_b_id].each do |uid|
      next unless scope.exists?(['user_a_id = ? OR user_b_id = ?', uid, uid])

      errors.add(:base, "Player #{uid} is already in another pair")
      break
    end
  end
end
