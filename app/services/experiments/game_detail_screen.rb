# frozen_string_literal: true

module Experiments
  # Assigns users to legacy (full match UI) vs simple (rotation MVP) game detail.
  class GameDetailScreen
    EXPERIMENT = :game_detail_screen
    ALTERNATIVES = %w[legacy simple].freeze

    def self.assign(controller, _user)
      forced = ENV.fetch('GAME_DETAIL_SCREEN_VARIANT', '').to_s.strip
      return forced if ALTERNATIVES.include?(forced)

      return 'simple' unless Split.configuration.enabled

      # Alternatives + weights: config/experiments.yml. Sticky bucket via session cookie.
      controller.ab_test(EXPERIMENT)
    end
  end
end
