# frozen_string_literal: true

module Matches
  class CreateService < ApplicationService
    def initialize(user:, game:, params:, edit_token: nil)
      @user = user
      @game = game
      @params = params
      @edit_token = edit_token
      @team_a_ids = Array(params[:team_a]).map(&:to_i)
      @team_b_ids = Array(params[:team_b]).map(&:to_i)
    end

    def call
      return failure('Forbidden', :forbidden) unless @game.can_manage?(user: @user, edit_token: @edit_token)
      return failure('Game is not active') if @game.finished? || @game.cancelled?
      return failure('Not enough players for a match') unless enough_players?

      all_ids = @team_a_ids + @team_b_ids
      return failure('Must have players on both teams') if @team_a_ids.empty? || @team_b_ids.empty?
      return failure('Duplicate player IDs') if all_ids.uniq.length != all_ids.length

      roster_error = Matches::RosterValidator.error_for_create(@game, all_ids)
      return failure(roster_error) if roster_error

      arranged_as_pairs = ActiveModel::Type::Boolean.new.cast(@params[:arranged_as_pairs])
      if arranged_as_pairs
        pair_error = Games::PlayerPairConstraint.validate_lineup!(@game, @team_a_ids, @team_b_ids)
        return failure(pair_error) if pair_error
        quota_error = Games::PlayerPairConstraint.validate_pair_quota!(@game, @team_a_ids, @team_b_ids)
        return failure(quota_error) if quota_error
      end

      if @game.pending_queue_full?
        n = @game.configured_court_count
        return failure("Hàng chờ đầy (#{n}/#{n}) — bắt đầu hoặc xóa trận chờ trước")
      end

      next_number = (@game.matches.maximum(:match_number) || 0) + 1

      match = nil
      ActiveRecord::Base.transaction do
        match = @game.matches.create!(
          match_number: next_number,
          status: :pending
        )

        @team_a_ids.each { |uid| match.match_participations.create!(user_id: uid, team: :team_a) }
        @team_b_ids.each { |uid| match.match_participations.create!(user_id: uid, team: :team_b) }
        if arranged_as_pairs
          involved = Games::PlayerPairConstraint.pairs_in_lineup(@game, @team_a_ids, @team_b_ids)
          Games::PlayerPairConstraint.increment_pair_usage!(involved)
        end
      end

      match.match_participations.includes(user: :rank).load
      success(match: match)
    end

    private

    def enough_players?
      min = @game.doubles? ? 4 : 2
      @game.players_count >= min
    end
  end
end
