# frozen_string_literal: true

module Experiments
  class Catalog
    def self.assign(controller, user)
      {
        game_detail_screen: GameDetailScreen.assign(controller, user)
      }
    end
  end
end
