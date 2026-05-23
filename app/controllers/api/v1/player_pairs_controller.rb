# frozen_string_literal: true

module Api
  module V1
    class PlayerPairsController < BaseController
      before_action :set_game
      before_action :set_pair, only: :destroy

      def create
        result = Games::PlayerPairsService.new(user: @current_user, game: @game).create(
          user_a_id: params[:user_a_id],
          user_b_id: params[:user_b_id]
        )
        if result.success?
          render json: pair_payload(result.data[:pair]), status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def destroy
        result = Games::PlayerPairsService.new(user: @current_user, game: @game).destroy(pair: @pair)
        if result.success?
          render json: { status: 'deleted', id: @pair.id }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      private

      def set_game
        @game = Game.find(params[:game_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def set_pair
        @pair = @game.game_player_pairs.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Pair not found' }, status: :not_found
      end

      def pair_payload(pair)
        {
          id: pair.id,
          user_a_id: pair.user_a_id,
          user_b_id: pair.user_b_id,
          status: pair.status
        }
      end
    end
  end
end
