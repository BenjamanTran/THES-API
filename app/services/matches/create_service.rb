# frozen_string_literal: true

module Matches
  class CreateService < ApplicationService
    def initialize(user:, game:, params:)
      @user = user
      @game = game
      @team_a_ids = Array(params[:team_a]).map(&:to_i)
      @team_b_ids = Array(params[:team_b]).map(&:to_i)
    end

    def call
      return failure('Only the host can create matches', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Game must be ongoing or full') unless @game.ongoing? || @game.full?

      all_ids = @team_a_ids + @team_b_ids
      return failure('Must have players on both teams') if @team_a_ids.empty? || @team_b_ids.empty?
      return failure('Duplicate player IDs') if all_ids.uniq.length != all_ids.length

      participant_ids = @game.game_participations.pluck(:user_id)
      invalid = all_ids - participant_ids
      return failure("Players not in this game: #{invalid.join(', ')}") if invalid.any?

      next_number = (@game.matches.maximum(:match_number) || 0) + 1

      match = nil
      ActiveRecord::Base.transaction do
        match = @game.matches.create!(
          match_number: next_number,
          status: :ongoing,
          started_at: Time.current
        )

        @team_a_ids.each { |uid| match.match_participations.create!(user_id: uid, team: :team_a) }
        @team_b_ids.each { |uid| match.match_participations.create!(user_id: uid, team: :team_b) }
      end

      match.match_participations.includes(user: :rank).load
      success(match: match)
    end
  end
end
