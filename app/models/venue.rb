# frozen_string_literal: true

class Venue < ApplicationRecord
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :games, dependent: :nullify

  validates :name, presence: true, length: { maximum: 200 }
  validates :mapbox_id, uniqueness: true, allow_nil: true

  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :search, ->(q) { where('name LIKE :q OR address LIKE :q OR district LIKE :q', q: "%#{q}%") if q.present? }
  scope :verified_first, -> { order(verified: :desc, name: :asc) }
  scope :suggested_by_games, lambda { |limit = 5|
    left_joins(:games)
      .group(:id)
      .having('COUNT(games.id) > 0')
      .order(Arel.sql('COUNT(games.id) DESC'))
      .limit(limit)
      .select('venues.*, COUNT(games.id) AS games_count')
  }
end
