# frozen_string_literal: true

module Games
  class AdjustSessionPlayedService < ApplicationService
    ALLOWED_DELTAS = [-1, 1].freeze

    def initialize(user:, game:, target_user_id:, delta:)
      super()
      @user = user
      @game = game
      @target_user_id = target_user_id
      @delta = delta.to_i
    end

    def call
      unless @game.host_or_co_host?(@user)
        return failure('Only host or co-host can adjust session count', :forbidden)
      end
      return failure('delta must be 1 or -1') unless ALLOWED_DELTAS.include?(@delta)

      gp = @game.game_participations.find_by(user_id: @target_user_id)
      return failure('Player not found in this game', :not_found) unless gp

      new_count = [gp.session_played_count + @delta, 0].max
      gp.update!(session_played_count: new_count)
      success(participation: gp.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    end
  end
end
