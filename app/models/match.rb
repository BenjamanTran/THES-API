# frozen_string_literal: true

class Match < ApplicationRecord
  belongs_to :game
  has_many :match_participations, dependent: :destroy
  has_many :users, through: :match_participations

  enum :status, { pending: 0, ongoing: 1, finished: 2 }

  validates :match_number, presence: true,
                           uniqueness: { scope: :game_id },
                           numericality: { greater_than: 0 }

  scope :ordered, -> { order(:match_number) }
end
