# frozen_string_literal: true

module Api
  module V1
    class PlaceholdersController < BaseController
      before_action :set_game

      def create
        result = Games::PlaceholderService.new(
          user: @current_user,
          game: @game,
          params: placeholder_params
        ).create
        if result.success?
          broadcast_game_refresh
          render json: player_payload(participation_for_player(result.data[:player].id)), status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def update
        result = Games::PlaceholderService.new(
          user: @current_user,
          game: @game,
          params: placeholder_params.merge(id: params[:id])
        ).update
        if result.success?
          broadcast_game_refresh
          render json: player_payload(participation_for_player(result.data[:player].id))
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def destroy
        result = Games::PlaceholderService.new(
          user: @current_user,
          game: @game,
          params: { id: params[:id] }
        ).destroy
        if result.success?
          broadcast_game_refresh
          render json: { status: 'deleted', user_id: params[:id].to_i }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      private

      def set_game
        @game = Game.find(params[:game_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found and return
      end

      def participation_for_player(user_id)
        @game.game_participations.includes(user: :rank).find_by!(user_id: user_id)
      end

      def placeholder_params
        source = params[:placeholder].is_a?(ActionController::Parameters) ? params[:placeholder] : params
        source.permit(:name, :gender, :tier, :stars).to_h.symbolize_keys
      end

      def broadcast_game_refresh
        Games::CableBroadcaster.broadcast(game: @game.reload, event: 'game.refresh')
      end

      def player_payload(participation)
        user = participation.user
        payload = {
          id: user.id,
          name: user.name,
          gender: user.gender,
          role: participation.role,
          placeholder: true,
          arrived_at_court: participation.arrived_at_court
        }
        payload[:rank] = game_player_rank_payload(user) if user.rank
        payload[:declared_rank] = declared_rank_payload(user.rank) if user.rank
        merge_session_skill!(payload, participation)
        payload[:session_matches] = { played: participation.session_played_count, wins: 0, losses: 0 }
        payload
      end
    end
  end
end
