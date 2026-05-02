# frozen_string_literal: true

module Api
  module V1
    class GamesController < BaseController
      skip_before_action :set_current_user, only: %i[index show search]
      before_action :set_current_user_optional, only: %i[index show search]
      before_action :set_game, only: %i[show join leave]

      MAX_PER_PAGE = 50

      def index
        games = filtered_games.page(params[:page]).per(clamped_per_page)

        render json: { games: games.map { |g| game_list_item(g) }, meta: pagination_meta(games) }
      end

      def search
        result = Games::SearchService.call(params: search_params, user: @current_user)
        render json: { games: result.data[:games] }
      end

      def show
        render json: game_detail(@game)
      end

      def create
        result = service.create
        if result.success?
          render json: game_list_item(result.data[:game]), status: :created
        else
          render json: { errors: result.error }, status: :unprocessable_content
        end
      end

      def join
        result = service(game: @game).join
        if result.success?
          body = { status: 'joined' }
          body[:warning] = result.data[:warning] if result.data[:warning]
          render json: body, status: :ok
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
        @game = Game.includes(:host, :users).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def service(game: nil)
        Games::GameService.new(user: @current_user, game: game, params: game_params)
      end

      def game_params
        params.permit(:start_time, :end_time, :lat, :lng, :match_type, :min_tier, :max_tier, :max_players)
      end

      def search_params
        params.permit(:lat, :lng, :radius, :tier, :from_time, :status, :page, :per_page).to_h.symbolize_keys
      end

      def filtered_games
        Game.upcoming
            .by_status(params[:status])
            .by_time_from(params[:from_time])
            .by_time_to(params[:to_time])
            .by_tier(params[:tier])
            .order(start_time: :asc)
      end

      def clamped_per_page
        [params[:per_page].to_i, MAX_PER_PAGE].min.clamp(1, MAX_PER_PAGE)
      end

      def pagination_meta(collection)
        {
          page: collection.current_page,
          per_page: collection.limit_value,
          total: collection.total_count,
          total_pages: collection.total_pages
        }
      end

      def game_list_item(game)
        item = game.slice(:id, :start_time, :end_time, :status, :players_count, :max_players)
        item[:fit_level] = game.fit_level(@current_user) if @current_user
        item
      end

      def game_detail(game)
        {
          id: game.id,
          start_time: game.start_time,
          end_time: game.end_time,
          status: game.status,
          match_type: game.match_type,
          players_count: game.players_count,
          max_players: game.max_players,
          host: { id: game.host&.id, name: game.host&.name },
          players: game.users.map { |u| { id: u.id, name: u.name } }
        }
      end
    end
  end
end
