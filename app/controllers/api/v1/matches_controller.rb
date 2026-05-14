# frozen_string_literal: true

module Api
  module V1
    class MatchesController < BaseController
      before_action :set_game
      before_action :set_match, only: %i[finish destroy]

      def index
        matches = @game.matches.includes(match_participations: { user: :rank }).ordered
        render json: { matches: matches.map { |m| match_payload(m) } }
      end

      def create
        result = Matches::CreateService.call(user: @current_user, game: @game, params: create_params)
        if result.success?
          render json: match_payload(result.data[:match]), status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def finish
        result = Matches::FinishService.call(user: @current_user, match: @match, params: finish_params)
        if result.success?
          render json: {
            match: match_payload(result.data[:match]),
            participants: result.data[:participants]
          }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def destroy
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only the host can delete matches' }, status: :forbidden
        end
        if @match.finished?
          return render json: { error: 'Cannot delete a finished match' }, status: :unprocessable_entity
        end

        @match.destroy!
        render json: { message: 'Match deleted' }
      end

      private

      def set_game
        @game = Game.find(params[:game_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def set_match
        @match = @game.matches.includes(match_participations: { user: :rank }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Match not found' }, status: :not_found
      end

      def create_params
        params.permit(team_a: [], team_b: [])
      end

      def finish_params
        params.permit(:team_a_score, :team_b_score, :winner_team)
      end

      def match_payload(match)
        mp = match.match_participations.loaded? ? match.match_participations : match.match_participations.includes(user: :rank)
        team_a = mp.select(&:team_a?)
        team_b = mp.select(&:team_b?)
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          winner_team: match.winner_team,
          started_at: match.started_at,
          finished_at: match.finished_at,
          team_a: team_a.map { |mp_entry| player_entry(mp_entry) },
          team_b: team_b.map { |mp_entry| player_entry(mp_entry) }
        }
      end

      def player_entry(mp_entry)
        user = mp_entry.user
        entry = { id: user.id, name: user.name, gender: user.gender, winner: mp_entry.winner }
        entry[:rank] = rank_payload(user.rank) if user.rank
        entry
      end
    end
  end
end
