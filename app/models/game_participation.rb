class GameParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :team, { team_a: 0, team_b: 1 }

  validates :team, presence: true
  validates :user_id, uniqueness: { scope: :game_id }
end
