# frozen_string_literal: true

module Users
  class CleanupPlaceholderUsersJob < ApplicationJob
    queue_as :default

    RETENTION_DAYS = 30

    def perform
      cutoff = RETENTION_DAYS.days.ago
      scope = User.placeholders.joins(game_participations: :game).where(
        games: { status: [Game.statuses[:finished], Game.statuses[:cancelled]] }
      ).where(games: { end_time: ...cutoff }).distinct

      deleted = 0
      scope.find_each do |user|
        user.destroy!
        deleted += 1
      rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey => e
        Rails.logger.warn("[CleanupPlaceholderUsersJob] skip user #{user.id}: #{e.message}")
      end

      Rails.logger.info("[CleanupPlaceholderUsersJob] deleted #{deleted} placeholder users")
      deleted
    end
  end
end
