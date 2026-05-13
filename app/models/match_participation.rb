# frozen_string_literal: true

class MatchParticipation < ApplicationRecord
  belongs_to :match
  belongs_to :user

  enum :team, { team_a: 0, team_b: 1 }

  validates :team, presence: true
  validates :user_id, uniqueness: { scope: :match_id }
end
