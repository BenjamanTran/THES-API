# frozen_string_literal: true

module Games
  class UpdateStatusesJob < ApplicationJob
    queue_as :default

    def perform
      now = Time.current

      transition_to_ongoing(now)
      transition_to_finished(now)
    end

    private

    def transition_to_ongoing(now)
      Game.where(status: %i[open full])
          .where('start_time <= ? AND end_time > ?', now, now)
          .update_all(status: :ongoing, updated_at: now)
    end

    def transition_to_finished(now)
      Game.where(status: %i[open full ongoing])
          .where('end_time <= ?', now)
          .update_all(status: :finished, updated_at: now)
    end
  end
end
