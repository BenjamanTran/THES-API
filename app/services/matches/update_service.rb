# frozen_string_literal: true

module Matches
  class UpdateService < ApplicationService
    def initialize(user:, game:, match:, params:, edit_token: nil)
      @user = user
      @game = game
      @match = match
      @edit_token = edit_token
      @team_a_ids = Array(params[:team_a]).map(&:to_i)
      @team_b_ids = Array(params[:team_b]).map(&:to_i)
    end

    def call
      return failure('Only host or co-host can edit matches', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Cannot edit a finished match') if @match.finished?
      return failure('Game is not active') if @game.finished? || @game.cancelled?
      return failure('Not enough players for a match') unless enough_players?

      all_ids = @team_a_ids + @team_b_ids
      return failure('Must have players on both teams') if @team_a_ids.empty? || @team_b_ids.empty?
      return failure('Duplicate player IDs') if all_ids.uniq.length != all_ids.length

      roster_error = Matches::RosterValidator.error_for_create(@game, all_ids)
      return failure(roster_error) if roster_error

      ActiveRecord::Base.transaction do
        @match.match_participations.destroy_all
        @team_a_ids.each { |uid| @match.match_participations.create!(user_id: uid, team: :team_a) }
        @team_b_ids.each { |uid| @match.match_participations.create!(user_id: uid, team: :team_b) }
      end

      @match.match_participations.includes(user: :rank).load
      success(match: @match)
    end

    private

    def enough_players?
      min = @game.doubles? ? 4 : 2
      @game.players_count >= min
    end
  end
end
