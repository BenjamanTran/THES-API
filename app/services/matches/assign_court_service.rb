# frozen_string_literal: true

module Matches
  class AssignCourtService
    def self.call(game:, exclude_match_id: nil)
      courts = normalized_courts(game)
      scope = game.matches.ongoing
      scope = scope.where.not(id: exclude_match_id) if exclude_match_id
      taken = scope.pluck(:court_number).compact
      courts.find { |c| !taken.include?(c) }
    end

    def self.normalized_courts(game)
      list = Array(game.courts).map(&:to_i).select(&:positive?).sort.uniq
      return list if list.any?

      slots = [game.matches.ongoing.count + 1, 4].max
      (1..slots).to_a
    end

    # Ongoing matches started before court_number existed — assign on read so invite/live views show sân.
    def self.backfill_ongoing!(game)
      game.matches.ongoing.where(court_number: nil).order(:match_number, :id).find_each do |match|
        court = call(game: game, exclude_match_id: match.id)
        match.update_column(:court_number, court) if court # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
