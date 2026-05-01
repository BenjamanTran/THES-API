module Api
  module V1
    class GamesController < BaseController
      before_action :set_game, only: %i[show join leave]

      def create
        result = service.create

        if result.success?
          render json: game_response(result.data[:game]), status: :created
        else
          render json: { errors: result.error }, status: :unprocessable_entity
        end
      end

      def show
        render json: game_response(@game)
      end

      def join
        result = service(game: @game).join

        if result.success?
          response = { status: "joined" }
          response[:warning] = result.data[:warning] if result.data[:warning]
          render json: response, status: :ok
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def leave
        result = service(game: @game).leave

        if result.success?
          render json: { status: "left" }, status: :ok
        else
          render json: { error: result.error }, status: result.status
        end
      end

      private

      def set_game
        @game = Game.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Game not found" }, status: :not_found
      end

      def service(game: nil)
        Games::GameService.new(user: @current_user, game: game, params: game_params)
      end

      def game_params
        params.permit(:start_time, :end_time, :lat, :lng, :match_type, :min_tier, :max_tier, :max_players)
      end

      def game_response(game)
        {
          id: game.id,
          start_time: game.start_time,
          end_time: game.end_time,
          status: game.status,
          match_type: game.match_type,
          lat: game.lat,
          lng: game.lng,
          min_tier: game.min_tier,
          max_tier: game.max_tier,
          max_players: game.max_players,
          players_count: game.players_count,
          host_id: game.host_id,
          location: game.location
        }
      end
    end
  end
end
