# frozen_string_literal: true

module Matches
  class UndoFinishService < ApplicationService
    UNDO_WINDOW = 5.seconds

    def initialize(user:, match:)
      @user = user
      @match = match
      @game = match.game
    end

    def call
      unless @game.host_id == @user.id || @game.game_participations.exists?(user_id: @user.id)
        return failure('Only participants can undo match finish', :forbidden)
      end
      return failure('Match is not finished') unless @match.finished?
      return failure('Undo window expired') unless undoable?

      had_ratings = @match.winner_team.present?

      ActiveRecord::Base.transaction do
        revert_ratings! if had_ratings

        @match.update!(
          status: :ongoing,
          team_a_score: nil,
          team_b_score: nil,
          winner_team: nil,
          finished_at: nil
        )
      end

      @match.reload
      @match.match_participations.includes(user: :rank).load
      success(match: @match)
    end

    private

    def undoable?
      @match.finished_at.present? && @match.finished_at >= UNDO_WINDOW.ago
    end

    def revert_ratings!
      @match.match_participations.each do |mp|
        rank = mp.user.rank
        next unless rank

        if mp.winner?
          rank.update!(
            wins: [rank.wins - 1, 0].max,
            matches_count: [rank.matches_count - 1, 0].max
          )
        else
          rank.update!(
            losses: [rank.losses - 1, 0].max,
            matches_count: [rank.matches_count - 1, 0].max
          )
        end
        mp.update!(winner: false)
        Users::GlobalRatingCalculator.sync!(user: mp.user)
      end
    end
  end
end
