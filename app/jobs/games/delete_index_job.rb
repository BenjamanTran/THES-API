# frozen_string_literal: true

module Games
  class DeleteIndexJob < ApplicationJob
    queue_as :elasticsearch

    def perform(game_id)
      GameRepository.new.delete_game(game_id)
    end
  end
end
