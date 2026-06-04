# frozen_string_literal: true

module Games
  class ToggleArrivedService < ApplicationService
    def initialize(user:, game:, target_user_id:, arrived:)
      super()
      @user = user
      @game = game
      @target_user_id = target_user_id
      @arrived = arrived
    end

    def call
      unless @game.host_or_co_host?(@user)
        return failure('Only host or co-host can update arrival status', :forbidden)
      end

      gp = @game.game_participations.find_by(user_id: @target_user_id)
      return failure('Player not found in this game', :not_found) unless gp

      gp.update!(arrived_at_court: @arrived)
      Games::PendingMatchSync.remove_user!(@game, @target_user_id) unless @arrived
      success(participation: gp.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    end
  end
end
