# frozen_string_literal: true

module Users
  class CleanupGuestsJob < ApplicationJob
    queue_as :default

    GUEST_TTL = 30.days

    def perform
      expired = User.guests.where(created_at: ...GUEST_TTL.ago)
      count = expired.count
      return Rails.logger.info("[CleanupGuests] No expired guests found") if count.zero?

      Rails.logger.info("[CleanupGuests] Found #{count} expired guest(s), cleaning up…")

      expired.find_each do |guest|
        ActiveRecord::Base.transaction do
          hosted_game_ids = Game.where(host_id: guest.id).pluck(:id)

          if hosted_game_ids.any?
            Match.where(game_id: hosted_game_ids).each do |match|
              match.match_participations.destroy_all
              match.destroy!
            end
            GameParticipation.where(game_id: hosted_game_ids).destroy_all
            Game.where(id: hosted_game_ids).destroy_all
          end

          guest.game_participations.each do |gp|
            gp.game.update_column(:players_count, [gp.game.players_count - 1, 0].max)
          end

          MatchParticipation.where(user_id: guest.id).destroy_all
          guest.game_participations.destroy_all
          guest.rank&.destroy!
          guest.user_skills.destroy_all
          guest.destroy!
        end

        Rails.logger.info("[CleanupGuests] Deleted guest ##{guest.id} (#{guest.name})")
      rescue StandardError => e
        Rails.logger.error("[CleanupGuests] Failed to delete guest ##{guest.id}: #{e.message}")
      end

      Rails.logger.info("[CleanupGuests] Done. Cleaned #{count} guest(s).")
    end
  end
end
