# frozen_string_literal: true

module Api
  module V1
    class GamesController < BaseController
      skip_before_action :set_current_user, only: %i[index show search]
      before_action :set_current_user_optional, only: %i[index show search]
      before_action :set_game,
                    only: %i[update join leave promote kick rate_player update_player adjust_session_played toggle_arrived transition]
      before_action :set_game_with_pairs, only: %i[show]

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

      def join
        result = service(game: @game).join
        if result.success?
          broadcast_game_refresh
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
          broadcast_game_refresh
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
          broadcast_game_refresh
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

        user_id = gp.user_id
        ActiveRecord::Base.transaction do
          Games::PlayerPairConstraint.destroy_pairs_for_user!(@game, user_id)
          Games::PendingMatchSync.remove_user!(@game, user_id)
          gp.destroy!
          @game.update!(players_count: @game.players_count - 1)
          @game.update!(status: :open) if @game.full?
        end

        broadcast_game_refresh
        render json: { status: 'kicked', user_id: user_id }
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

        broadcast_game_refresh
        render json: player_payload(gp.reload)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      def update_player
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can update players' }, status: :forbidden
        end

        gp = @game.game_participations.find_by(user_id: params[:user_id])
        return render json: { error: 'Player not found in this game' }, status: :not_found unless gp
        if gp.user.placeholder?
          return render json: { error: 'Use placeholder edit instead' }, status: :unprocessable_content
        end

        gender = params[:gender]&.to_s
        unless User.genders.key?(gender)
          return render json: { error: 'Invalid gender' }, status: :unprocessable_content
        end

        gp.user.update!(gender: gender)
        broadcast_game_refresh
        render json: player_payload(gp.reload)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      def toggle_arrived
        arrived = ActiveModel::Type::Boolean.new.cast(params[:arrived])
        result = Games::ToggleArrivedService.call(
          user: @current_user,
          game: @game,
          target_user_id: params[:user_id],
          arrived: arrived
        )
        if result.success?
          participation = result.data[:participation]
          player_json = player_payload(participation)
          broadcast_game_refresh
          render json: { player: player_json }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def adjust_session_played
        result = Games::AdjustSessionPlayedService.call(
          user: @current_user,
          game: @game,
          target_user_id: params[:user_id],
          delta: params[:delta]
        )
        if result.success?
          participation = result.data[:participation]
          player_json = player_payload(participation)
          broadcast_player_session_played(player_json)
          render json: { player: player_json }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def transition
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Forbidden' }, status: :forbidden
        end

        target = params[:status].to_s
        unless Game.statuses.key?(target)
          return render json: { error: 'Invalid status' }, status: :unprocessable_content
        end

        @game.update!(status: target)
        broadcast_game_refresh
        render json: game_detail(@game.reload)
      end

      private

      def broadcast_game_refresh
        Games::CableBroadcaster.broadcast(game: @game.reload, event: 'game.refresh')
      end

      def broadcast_player_session_played(player)
        Games::CableBroadcaster.broadcast(
          game: @game,
          event: 'player.session_played',
          payload: { player: player }
        )
      end

      def set_game
        @game = Game.includes(:host, game_participations: { user: :rank }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def set_game_with_pairs
        @game = Game.includes(:host, :game_player_pairs, game_participations: { user: :rank }).find(params[:id])
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
        params.permit(:max_players, :pair_matches_limit, courts: []).to_h
      end

      def search_params
        params.permit(:lat, :lng, :radius, :tier, :from_time, :status, :time_scope,
                      :page, :per_page, :sort, :not_full, :match_type, :price_max).to_h.symbolize_keys
      end

      def filtered_games
        scope = base_filtered_scope
        scope = mine_scope(scope) if mine_filter?
        scope = scope.includes(:host)
        apply_list_order(scope)
      end

      def apply_list_order(scope)
        if mine_filter? && params[:time].to_s != 'past'
          scope.order_active_first
        else
          scope.order(start_time: order_direction)
        end
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
        detail[:match_counts] = match_counts_for_game(game)
        participations_by_user = game.game_participations.index_by(&:user_id)
        live_matches = game.matches
                           .where(status: %i[ongoing pending])
                           .includes(match_participations: { user: :rank })
                           .order(status: :desc, match_number: :asc)
        detail[:matches] = live_matches.map { |m| match_summary(m, participations_by_user) }
        priority = live_matches.find(&:priority?)
        detail[:priority_match] = priority ? match_summary(priority, participations_by_user) : nil
        detail[:pair_matches_limit] = game.pair_matches_limit
        detail[:player_pairs] = game.game_player_pairs.select(&:active?).map { |p| player_pair_payload(p) }
        detail
      end

      def player_pair_payload(pair)
        {
          id: pair.id,
          user_a_id: pair.user_a_id,
          user_b_id: pair.user_b_id,
          status: pair.status,
          matches_used: pair.matches_used
        }
      end

      def match_counts_for_game(game)
        counts = game.matches.group(:status).count
        {
          pending: counts['pending'] || counts[0] || 0,
          ongoing: counts['ongoing'] || counts[1] || 0,
          finished: counts['finished'] || counts[2] || 0
        }
      end

      def match_summary(match, participations_by_user = nil)
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          winner_team: match.winner_team,
          priority: match.priority,
          court_number: match.court_number,
          team_a: match.match_participations.select(&:team_a?).map { |mp| match_player(mp, participations_by_user) },
          team_b: match.match_participations.select(&:team_b?).map { |mp| match_player(mp, participations_by_user) }
        }
      end

      def match_player(mp, participations_by_user = nil)
        user = mp.user
        gp = participations_by_user&.fetch(user.id, nil)
        entry = { id: user.id, name: user.name, gender: user.gender }.merge(player_avatar_fields(user))
        merge_session_skill!(entry, gp) if gp
        entry
      end

      def player_payload(participation)
        user = participation.user
        payload = {
          id: user.id,
          name: user.name,
          gender: user.gender,
          role: participation.role,
          placeholder: user.placeholder?,
          arrived_at_court: participation.arrived_at_court
        }.merge(player_avatar_fields(user))
        payload[:declared_rank] = declared_rank_payload(user.rank) if user.rank && !user.placeholder?
        merge_session_skill!(payload, participation)
        payload[:session_matches] = {
          played: participation.session_played_count,
          wins: 0,
          losses: 0
        }
        payload
      end
    end
  end
end
