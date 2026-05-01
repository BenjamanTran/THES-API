# frozen_string_literal: true

module Api
  module V1
    class GamesController < BaseController
      before_action :set_game, only: %i[show join leave]

      def show
        render json: game_response(@game)
      end

      def create
        result = service.create

        if result.success?
          render json: game_response(result.data[:game]), status: :created
        else
          render json: { errors: result.error }, status: :unprocessable_content
        end
      end

      def join
        result = service(game: @game).join

        if result.success?
          response = { status: 'joined' }
          response[:warning] = result.data[:warning] if result.data[:warning]
          render json: response, status: :ok
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def leave
        result = service(game: @game).leave

        if result.success?
          render json: { status: 'left' }, status: :ok
        else
          render json: { error: result.error }, status: result.status
        end
      end

      private

      def set_game
        @game = Game.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def service(game: nil)
        Games::GameService.new(user: @current_user, game: game, params: game_params)
      end

      def game_params
        params.permit(:start_time, :end_time, :lat, :lng, :match_type, :min_tier, :max_tier, :max_players)
      end

      def game_response(game)
        game.slice(
          :id, :start_time, :end_time, :status, :match_type,
          :lat, :lng, :min_tier, :max_tier, :max_players,
          :players_count, :host_id, :location
        )
      end
    end
  end
end
