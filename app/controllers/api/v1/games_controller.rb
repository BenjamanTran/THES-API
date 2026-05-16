# frozen_string_literal: true

module Api
  module V1
    class GamesController < BaseController
      skip_before_action :set_current_user, only: %i[index show search]
      before_action :set_current_user_optional, only: %i[index show search]
      before_action :set_game, only: %i[show update join leave promote kick rate_player]

      MAX_PER_PAGE = 50
      DEFAULT_PER_PAGE = 20

      def index
        games = filtered_games.page(params[:page]).per(clamped_per_page)

        render json: { games: games.map { |g| game_list_item(g) }, meta: pagination_meta(games) }
      end

      def search
        result = Games::SearchService.call(params: search_params, user: @current_user)
        render json: { games: result.data[:games], meta: result.data[:meta] }
      end

      def show
        render json: game_detail(@game)
      end

      def update
        result = Games::UpdateSettingsService.call(
          user: @current_user,
          game: @game,
          params: update_params
        )
        if result.success?
          render json: game_detail(result.data[:game])
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def create
        if @current_user.guest?
          return render json: { errors: ['Tài khoản khách không thể tạo trận'] }, status: :forbidden
        end

        result = service.create
        if result.success?
          game = result.data[:game]
          payload = game_list_item(game)
          payload[:invite_code] = game.invite_code
          render json: payload, status: :created
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

      def promote
        unless @game.host_id == @current_user.id
          return render json: { error: 'Only the host can manage co-hosts' },
                        status: :forbidden
        end

        gp = @game.game_participations.find_by(user_id: params[:user_id])
        return render json: { error: 'Player not found in this game' }, status: :not_found unless gp
        return render json: { error: 'Cannot promote the host' }, status: :unprocessable_content if gp.user_id == @game.host_id
        if gp.user.placeholder?
          return render json: { error: 'Cannot promote a placeholder player' }, status: :unprocessable_content
        end

        new_role = gp.co_host? ? :player : :co_host
        gp.role = new_role
        if gp.save
          render json: { user_id: gp.user_id, role: gp.role }
        else
          render json: { error: gp.errors.full_messages.join(', ') }, status: :unprocessable_content
        end
      end

      def kick
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-hosts can kick players' }, status: :forbidden
        end

        gp = @game.game_participations.find_by(user_id: params[:user_id])
        return render json: { error: 'Player not found in this game' }, status: :not_found unless gp
        return render json: { error: 'Cannot kick the host' }, status: :unprocessable_content if gp.user_id == @game.host_id
        if gp.user.placeholder?
          return render json: { error: 'Use remove placeholder instead' }, status: :unprocessable_content
        end

        if gp.co_host? && @game.host_id != @current_user.id
          return render json: { error: 'Only the host can kick co-hosts' }, status: :forbidden
        end

        ActiveRecord::Base.transaction do
          gp.destroy!
          @game.update!(players_count: @game.players_count - 1)
          @game.update!(status: :open) if @game.full?
        end

        render json: { status: 'kicked', user_id: params[:user_id].to_i }
      end

      def rate_player
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can rate players' }, status: :forbidden
        end

        gp = @game.game_participations.find_by(user_id: params[:user_id])
        return render json: { error: 'Player not found in this game' }, status: :not_found unless gp

        tier_key = GameParticipation::HOST_TIER_MAP[params[:tier]]
        return render json: { error: 'Invalid tier' }, status: :unprocessable_content unless tier_key

        gp.update!(
          host_rated_tier: tier_key,
          host_rated_stars: params[:stars].to_i,
          host_rating_note: params[:note].presence
        )
        Users::GlobalRatingCalculator.sync!(user: gp.user)

        render json: player_payload(gp.reload)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      private

      def set_game
        @game = Game.includes(:host, game_participations: { user: :rank },
                              matches: { match_participations: { user: :rank } }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def service(game: nil)
        Games::GameService.new(user: @current_user, game: game, params: game_params)
      end

      def game_params
        params.permit(:start_time, :end_time, :lat, :lng, :match_type, :min_tier, :max_tier,
                      :max_players, :description, :title, :min_price, :max_price, :venue_id, courts: [])
      end

      def update_params
        params.permit(:max_players, courts: []).to_h
      end

      def search_params
        params.permit(:lat, :lng, :radius, :tier, :from_time, :status,
                      :page, :per_page, :sort, :not_full, :match_type, :price_max).to_h.symbolize_keys
      end

      def filtered_games
        scope = base_filtered_scope
        scope = mine_scope(scope) if mine_filter?
        scope.includes(:host).order(start_time: order_direction)
      end

      def base_filtered_scope
        Game.by_time(params[:time])
            .by_status(params[:status])
            .by_time_from(params[:from_time])
            .by_time_to(params[:to_time])
            .by_tier(params[:tier])
      end

      def order_direction
        params[:time].to_s == 'past' ? :desc : :asc
      end

      def mine_filter?
        ActiveModel::Type::Boolean.new.cast(params[:mine])
      end

      def mine_scope(scope)
        return scope.none unless @current_user

        scope.hosted_or_joined_by(@current_user)
      end

      def clamped_per_page
        requested = params[:per_page].to_i
        requested = DEFAULT_PER_PAGE if requested <= 0
        requested.clamp(1, MAX_PER_PAGE)
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
        item = game.slice(:id, :start_time, :end_time, :status, :match_type,
                          :players_count, :max_players, :lat, :lng, :location,
                          :description, :title, :min_tier, :max_tier, :courts,
                          :min_price, :max_price)
        item[:host] = { id: game.host&.id, name: game.host&.name }
        item[:fit_level] = game.fit_level(@current_user) if @current_user
        item[:matches_count] = game.matches_count
        item[:matches_finished] = game.matches_count.positive? ? game.matches.where(status: :finished).count : 0
        item
      end

      def game_detail(game)
        detail = game.slice(:id, :start_time, :end_time, :status, :match_type,
                            :players_count, :max_players, :lat, :lng, :location,
                            :description, :title, :min_tier, :max_tier, :courts,
                            :min_price, :max_price, :invite_code)
        detail[:host] = { id: game.host&.id, name: game.host&.name }
        detail[:players] = game.game_participations.map { |gp| player_payload(gp) }
        detail[:fit_level] = game.fit_level(@current_user) if @current_user
        detail[:matches] = game.matches.sort_by(&:match_number).map { |m| match_summary(m) }
        detail
      end

      def match_summary(match)
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          winner_team: match.winner_team,
          team_a: match.match_participations.select(&:team_a?).map { |mp| match_player(mp) },
          team_b: match.match_participations.select(&:team_b?).map { |mp| match_player(mp) }
        }
      end

      def match_player(mp)
        user = mp.user
        entry = { id: user.id, name: user.name, gender: user.gender }
        entry[:rank] = rank_payload(user.rank) if user.rank
        entry
      end

      def player_payload(participation)
        user = participation.user
        payload = {
          id: user.id,
          name: user.name,
          gender: user.gender,
          role: participation.role,
          placeholder: user.placeholder?
        }
        if user.rank
          payload[:rank] = rank_payload(user.rank)
          payload[:declared_rank] = declared_rank_payload(user.rank)
        end
        if participation.host_rated_tier.present?
          payload[:host_rated_tier] = participation.host_rated_tier_key
          payload[:host_rated_stars] = participation.host_rated_stars
          payload[:host_rating_note] = participation.host_rating_note
        end
        payload
      end
    end
  end
end
