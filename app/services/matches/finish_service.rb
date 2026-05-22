# frozen_string_literal: true

module Matches
  class FinishService < ApplicationService
    def initialize(user:, match:, params:)
      @user = user
      @match = match
      @game = match.game
      @score_a = params[:team_a_score]&.to_i
      @score_b = params[:team_b_score]&.to_i
      @winner_team = params[:winner_team]
    end

    def call
      unless @game.host_id == @user.id || @game.game_participations.exists?(user_id: @user.id)
        return failure('Only participants can finish matches', :forbidden)
      end
      return failure('Match is already finished') if @match.finished?

      has_scores = !@score_a.nil? && !@score_b.nil?
      winner_only = @winner_team.present? && !has_scores
      participants_data = []

      ActiveRecord::Base.transaction do
        if winner_only
          @match.update!(
            winner_team: @winner_team,
            status: :finished,
            finished_at: Time.current
          )
          update_participations_and_ratings!(participants_data)
        elsif has_scores
          return failure('Scores must be between 0 and 99') unless valid_scores?

          determine_winner! if @winner_team.blank?
          return failure('Winner team required when scores are tied') if @winner_team.blank?

          @match.update!(
            team_a_score: @score_a,
            team_b_score: @score_b,
            winner_team: @winner_team,
            status: :finished,
            finished_at: Time.current
          )

          update_participations_and_ratings!(participants_data)
        else
          @match.update!(status: :finished, finished_at: Time.current)
          @match.match_participations.each do |mp|
            participants_data << {
              user_id: mp.user_id, name: mp.user.name,
              team: mp.team, winner: false, rating_change: 0
            }
          end
        end
      end

      @match.reload
      @match.match_participations.includes(user: :rank).load
      bust_profile_caches!
      success(match: @match, participants: participants_data)
    end

    private

    def bust_profile_caches!
      @match.match_participations.find_each do |mp|
        Users::ProfileCache.bust_for_user!(mp.user_id)
      end
      Rails.cache.delete("users/#{@game.host_id}/stats/v2") if @game.host_id
    end

    def valid_scores?
      @score_a.between?(0, 31) && @score_b.between?(0, 31)
    end

    def determine_winner!
      if @score_a > @score_b
        @winner_team = 'team_a'
      elsif @score_b > @score_a
        @winner_team = 'team_b'
      end
    end

    def update_participations_and_ratings!(participants_data)
      team_a_mps = @match.match_participations.select(&:team_a?)
      team_b_mps = @match.match_participations.select(&:team_b?)

      winners = @winner_team == 'team_a' ? team_a_mps : team_b_mps
      losers  = @winner_team == 'team_a' ? team_b_mps : team_a_mps

      winners.each { |mp| mp.update!(winner: true) }
      losers.each  { |mp| mp.update!(winner: false) }

      win_points = Users::GlobalRatingCalculator::MATCH_WIN_POINTS
      loss_points = Users::GlobalRatingCalculator::MATCH_LOSS_POINTS

      winners.each do |mp|
        rank = mp.user.rank || mp.user.create_rank!(tier: :newbie, rating: Users::GlobalRatingCalculator::DEFAULT_BASE_RATING)
        rank.update!(
          wins: rank.wins + 1,
          matches_count: rank.matches_count + 1,
          last_played_at: Time.current
        )
        Users::GlobalRatingCalculator.sync!(user: mp.user)
        participants_data << {
          user_id: mp.user_id, name: mp.user.name,
          team: mp.team, winner: true, rating_change: win_points
        }
      end

      losers.each do |mp|
        rank = mp.user.rank || mp.user.create_rank!(tier: :newbie, rating: Users::GlobalRatingCalculator::DEFAULT_BASE_RATING)
        rank.update!(
          losses: rank.losses + 1,
          matches_count: rank.matches_count + 1,
          last_played_at: Time.current
        )
        Users::GlobalRatingCalculator.sync!(user: mp.user)
        participants_data << {
          user_id: mp.user_id, name: mp.user.name,
          team: mp.team, winner: false, rating_change: -loss_points
        }
      end
    end
  end
end
