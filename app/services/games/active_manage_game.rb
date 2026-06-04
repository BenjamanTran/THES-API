# frozen_string_literal: true

module Games
  # Game the user hosts or co-hosts with a live session (ongoing status or match on court).
  module ActiveManageGame
    class << self
      def call(user:)
        return nil unless user&.id

        pick = game_with_ongoing_match(user) || game_with_ongoing_status(user)
        return nil unless pick

        { id: pick.id, title: pick.title }
      end

      private

      def game_with_ongoing_match(user)
        Game.managed_by(user)
            .manage_session_active
            .joins(:matches)
            .merge(Match.ongoing)
            .order('matches.started_at DESC')
            .first
      end

      def game_with_ongoing_status(user)
        Game.managed_by(user)
            .manage_session_active
            .where(status: Game.statuses[:ongoing])
            .order(start_time: :desc)
            .first
      end
    end
  end
end
