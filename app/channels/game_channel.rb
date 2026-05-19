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
    return member_view?(game) if current_user

    invite_spectator_view?(game)
  end

  def member_view?(game)
    game.host_id == current_user.id ||
      game.game_participations.exists?(user_id: current_user.id)
  end

  def invite_spectator_view?(game)
    return false unless game.spectator_viewable?

    code = params[:invite_code].to_s
    game.valid_invite_code?(code)
  end
end
