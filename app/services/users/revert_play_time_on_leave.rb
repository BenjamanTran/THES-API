# frozen_string_literal: true

module Users
  class RevertPlayTimeOnLeave
    def self.call(game:, participation:)
      new(game: game, participation: participation).call
    end

    def initialize(game:, participation:)
      @game = game
      @participation = participation
    end

    def call
      return unless @participation.play_time_credited?
      return if @participation.user.placeholder?

      duration = @game.duration_seconds
      return if duration <= 0

      rank = @participation.user.rank
      return unless rank

      rank.update!(play_time_seconds: [rank.play_time_seconds - duration, 0].max)
    end
  end
end
