# frozen_string_literal: true

class GameChannel < ApplicationCable::Channel
  def subscribed
    game = Game.find_by(id: params[:game_id])
    reject unless game
    reject unless can_view_game?(game)

    stream_for game
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def can_view_game?(game)
    game.host_id == current_user.id ||
      game.game_participations.exists?(user_id: current_user.id)
  end
end
