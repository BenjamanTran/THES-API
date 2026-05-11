# frozen_string_literal: true

module Games
  class IndexJob < ApplicationJob
    queue_as :elasticsearch

    def perform(game_id)
      return unless Rails.application.config.x.elasticsearch_enabled

      game = Game.find_by(id: game_id)
      return unless game

      GameRepository.new.index_game(game)
    end
  end
end
