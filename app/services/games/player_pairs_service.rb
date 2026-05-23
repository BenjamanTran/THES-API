# frozen_string_literal: true

module Games
  class PlayerPairsService < ApplicationService
    def initialize(user:, game:)
      super()
      @user = user
      @game = game
    end

    def create(user_a_id:, user_b_id:)
      return failure('Only host or co-host can manage pairs', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Pairs are only for doubles games') unless @game.doubles?
      return failure('Cannot edit a finished or cancelled game') if @game.finished? || @game.cancelled?

      user_a_id, user_b_id = GamePlayerPair.normalize_ids(user_a_id, user_b_id)
      pair = @game.game_player_pairs.build(
        user_a_id: user_a_id,
        user_b_id: user_b_id,
        status: :active,
        created_by: @user
      )

      if pair.save
        success(pair: pair)
      else
        failure(pair.errors.full_messages.join(', '))
      end
    end

    def destroy(pair:)
      return failure('Only host or co-host can manage pairs', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Pair not found', :not_found) unless pair.game_id == @game.id

      pair.destroy!
      success
    end
  end
end
