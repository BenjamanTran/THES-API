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
          .where(start_time: ..now, end_time: now..)
          .find_each { |game| game.update(status: :ongoing) }
    end

    def transition_to_finished(now)
      Game.where(status: %i[open full ongoing])
          .where(end_time: ..now)
          .find_each { |game| game.update(status: :finished) }
    end
  end
end
