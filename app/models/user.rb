# frozen_string_literal: true

class User < ApplicationRecord
  has_many :game_participations, dependent: :destroy
  has_many :games, through: :game_participations
  has_one :rank, dependent: :destroy
  has_many :user_skills, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
