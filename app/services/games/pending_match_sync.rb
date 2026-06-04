# frozen_string_literal: true

module Games
  # Removes a user from pending lineups when they leave, are kicked, or are unmarked arrived-at-court.
  class PendingMatchSync
    def self.remove_user!(game, user_id)
      min_roster = game.doubles? ? 4 : 2
      game.matches.pending.includes(:match_participations).find_each do |match|
        match.match_participations.where(user_id: user_id).destroy_all
        match.destroy! if match.match_participations.count < min_roster
      end
    end
  end
end
