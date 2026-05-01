# frozen_string_literal: true

module GameSearchable
  extend ActiveSupport::Concern

  ALIAS_NAME = "games_#{Rails.env}".freeze

  included do
    include Elasticsearch::Model

    index_name ALIAS_NAME

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mappings dynamic: false do
        indexes :start_time, type: :date
        indexes :end_time, type: :date
        indexes :status, type: :keyword
        indexes :location, type: :geo_point
        indexes :min_tier, type: :integer
        indexes :max_tier, type: :integer
        indexes :players_count, type: :integer
        indexes :max_players, type: :integer
        indexes :match_type, type: :keyword
      end
    end

    after_commit :enqueue_index, on: %i[create update]
    after_commit :enqueue_delete, on: :destroy
  end

  def as_indexed_json(_options = {})
    {
      start_time: start_time&.iso8601,
      end_time: end_time&.iso8601,
      status: status,
      location: location_for_index,
      min_tier: self.class.min_tiers[min_tier],
      max_tier: self.class.max_tiers[max_tier],
      players_count: players_count,
      max_players: max_players,
      match_type: match_type
    }
  end

  class_methods do
    def new_index_name
      "#{ALIAS_NAME}_#{Time.current.strftime('%Y%m%d%H%M%S')}"
    end
  end

  private

  def location_for_index
    return if lat.blank? || lng.blank?

    { lat: lat.to_f, lon: lng.to_f }
  end

  def enqueue_index
    Games::IndexJob.perform_later(id)
  end

  def enqueue_delete
    Games::DeleteIndexJob.perform_later(id)
  end
end
