# frozen_string_literal: true

module Games
  module CableBroadcaster
    module_function

    def broadcast(game:, event:, payload: {})
      GameChannel.broadcast_to(
        game,
        {
          event: event,
          game_id: game.id,
          revision: Time.current.to_i,
          **payload
        }
      )
    rescue StandardError => e
      Rails.logger.error("[CableBroadcaster] #{event} game=#{game.id} failed: #{e.class}: #{e.message}")
    end
  end
end
