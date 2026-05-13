# frozen_string_literal: true

module Ranks
  class RatingCalculator
    K_FACTOR = 32

    # Returns an array of [rating_delta] for each winner and loser.
    # winner_ratings: array of current ratings for the winning team
    # loser_ratings:  array of current ratings for the losing team
    def self.call(winner_ratings:, loser_ratings:)
      avg_winner = winner_ratings.sum.to_f / winner_ratings.size
      avg_loser  = loser_ratings.sum.to_f / loser_ratings.size

      expected_winner = 1.0 / (1.0 + 10**((avg_loser - avg_winner) / 400.0))
      expected_loser  = 1.0 - expected_winner

      winner_delta = (K_FACTOR * (1.0 - expected_winner)).round
      loser_delta  = (K_FACTOR * (0.0 - expected_loser)).round

      {
        winner_delta: [winner_delta, 1].max,
        loser_delta: [loser_delta, -K_FACTOR].max
      }
    end
  end
end
