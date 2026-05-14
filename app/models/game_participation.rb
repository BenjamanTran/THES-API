# frozen_string_literal: true

class GameParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :team, { team_a: 0, team_b: 1 }
  enum :role, { player: 0, co_host: 1 }

  validates :team, presence: true
  validates :user_id, uniqueness: { scope: :game_id }
  validate :max_co_hosts, if: :co_host?

  private

  def max_co_hosts
    count = game.game_participations.co_host.where.not(id: id).count
    errors.add(:role, 'maximum 3 co-hosts per game') if count >= 3
  end
end
