module Api
  module V1
    class GamesController < BaseController
      before_action :set_game, only: %i[show join leave]

      def create
        game = Game.new(game_params)
        game.host = @current_user
        game.status = :open
        game.players_count = 1

        ActiveRecord::Base.transaction do
          game.save!
          game.game_participations.create!(user: @current_user, team: :team_a)
        end

        render json: game_response(game), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def show
        render json: game_response(@game)
      end

      def join
        warning = nil

        unless @game.open?
          return render json: { error: "Game is not open for joining" }, status: :unprocessable_entity
        end

        if @game.game_participations.exists?(user: @current_user)
          return render json: { error: "You have already joined this game" }, status: :unprocessable_entity
        end

        if time_conflict?(@current_user, @game)
          return render json: { error: "You have a time conflict with another game" }, status: :conflict
        end

        if tier_mismatch?(@current_user, @game)
          warning = "This match may not fit your level"
        end

        team = assign_team(@game)

        ActiveRecord::Base.transaction do
          @game.lock!
          if @game.players_count >= @game.max_players
            return render json: { error: "Game is already full" }, status: :unprocessable_entity
          end

          @game.game_participations.create!(user: @current_user, team: team)
          @game.increment!(:players_count)
          @game.update!(status: :full) if @game.players_count >= @game.max_players
        end

        response = { status: "joined" }
        response[:warning] = warning if warning
        render json: response, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def leave
        participation = @game.game_participations.find_by(user: @current_user)
        unless participation
          return render json: { error: "You are not in this game" }, status: :unprocessable_entity
        end

        if @game.ongoing?
          return render json: { error: "Cannot leave an ongoing game" }, status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          if @current_user.id == @game.host_id
            @game.update!(status: :cancelled)
            @game.game_participations.destroy_all
            @game.update!(players_count: 0)
          else
            participation.destroy!
            @game.decrement!(:players_count)
            @game.update!(status: :open) if @game.full?
          end
        end

        render json: { status: "left" }, status: :ok
      end

      private

      def set_game
        @game = Game.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Game not found" }, status: :not_found
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

      def time_conflict?(user, game)
        user.games
            .where.not(id: game.id)
            .where.not(status: :cancelled)
            .where("start_time < ? AND end_time > ?", game.end_time, game.start_time)
            .exists?
      end

      def tier_mismatch?(user, game)
        rank = user.rank
        return false unless rank

        tiers = Game::TIERS
        user_tier_val = tiers[rank.tier] || 0
        min_val = tiers[game.min_tier] || 0
        max_val = tiers[game.max_tier] || 0

        user_tier_val < min_val || user_tier_val > max_val
      end

      def assign_team(game)
        team_a_count = game.game_participations.team_a.count
        team_b_count = game.game_participations.team_b.count
        team_a_count <= team_b_count ? :team_a : :team_b
      end
    end
  end
end
