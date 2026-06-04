# frozen_string_literal: true

module Matches
  class RosterValidator
    def self.error_for_create(game, user_ids)
      error_in_game(game, user_ids) || error_arrived(game, user_ids)
    end

    def self.error_for_start(game, match)
      user_ids = match.match_participations.pluck(:user_id)
      min = game.doubles? ? 4 : 2
      return "Trận chờ thiếu người (#{user_ids.size}/#{min})" if user_ids.size < min

      error_in_game(game, user_ids)
    end

    def self.error_in_game(game, user_ids)
      participant_ids = game.game_participations.pluck(:user_id)
      gone = user_ids - participant_ids
      return nil if gone.empty?

      "Có người đã rời buổi chơi: #{labels_for(gone)} — sửa hoặc xóa trận chờ"
    end

    def self.error_arrived(game, user_ids)
      arrived_ids = game.game_participations.where(arrived_at_court: true).pluck(:user_id)
      missing = user_ids - arrived_ids
      return nil if missing.empty?

      "Chưa đánh dấu đã đến sân: #{labels_for(missing)}"
    end

    def self.labels_for(user_ids)
      User.where(id: user_ids).map { |u| u.name.presence || "##{u.id}" }.join(', ')
    end
  end
end
