# frozen_string_literal: true

module Api
  module V1
    class InvitesController < BaseController
      skip_before_action :set_current_user

      before_action :set_game_by_code

      def show
        render json: invite_payload
      end

      def join
        return render json: { error: 'Game is not open for joining' }, status: :unprocessable_content unless joinable?

        user = nil
        ActiveRecord::Base.transaction do
          user = User.create!(
            name: params[:name],
            gender: params[:gender] || :unspecified,
            guest: true
          )

          tier_key = params[:tier]&.to_sym || :newbie
          stars = params[:stars] || 3
          rating = Rank.rating_from_tier_and_stars(tier_key, stars)
          user.create_rank!(tier: tier_key, rating: rating, division: tier_key == :professional ? nil : 3)

          team = assign_team
          @game.game_participations.create!(user: user, team: team)
          @game.update!(players_count: @game.players_count + 1)
          @game.update!(status: :full) if @game.players_count >= @game.max_players
        end

        sign_in!(user)
        render json: { user: user_payload(user), game_id: @game.id }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      private

      def set_game_by_code
        @game = Game.includes(:host).find_by!(invite_code: params[:code])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invite link not found' }, status: :not_found
      end

      def joinable?
        !@game.finished? && !@game.cancelled? && @game.players_count < @game.max_players
      end

      def assign_team
        a = @game.game_participations.team_a.count
        b = @game.game_participations.team_b.count
        a <= b ? :team_a : :team_b
      end

      def invite_payload
        {
          game: {
            id: @game.id,
            description: @game.description,
            match_type: @game.match_type,
            status: @game.status,
            players_count: @game.players_count,
            max_players: @game.max_players,
            start_time: @game.start_time,
            end_time: @game.end_time,
            location: @game.location,
            host_name: @game.host&.name
          }
        }
      end
    end
  end
end
