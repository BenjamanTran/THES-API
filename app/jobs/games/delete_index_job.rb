# frozen_string_literal: true

module Games
  class DeleteIndexJob < ApplicationJob
    queue_as :elasticsearch

    def perform(game_id)
      return unless Rails.application.config.x.elasticsearch_enabled

      GameRepository.new.delete_game(game_id)
    end
  end
end
