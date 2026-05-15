# frozen_string_literal: true

module Users
  class CleanupUnverifiedUsersJob < ApplicationJob
    queue_as :default

    UNVERIFIED_TTL = 30.days

    def perform
      scope = User.unverified.where(created_at: ...UNVERIFIED_TTL.ago)
      count = scope.count
      return Rails.logger.info('[CleanupUnverified] No expired unverified users') if count.zero?

      Rails.logger.info("[CleanupUnverified] Deleting #{count} unverified user(s)…")
      scope.find_each do |user|
        user.destroy!
        Rails.logger.info("[CleanupUnverified] Deleted user ##{user.id} (#{user.email})")
      rescue StandardError => e
        Rails.logger.error("[CleanupUnverified] Failed user ##{user.id}: #{e.message}")
      end
    end
  end
end
