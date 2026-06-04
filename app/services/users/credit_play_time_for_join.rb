# frozen_string_literal: true

module Users
  # Credit game window duration (start_time → end_time) once on join, not per match.
  class CreditPlayTimeForJoin
    def self.call(game:, user:)
      new(game: game, user: user).call
    end

    def initialize(game:, user:)
      @game = game
      @user = user
    end

    def call
      return if @user.placeholder?

      duration = @game.duration_seconds
      return if duration <= 0

      participation = @game.game_participations.find_by(user_id: @user.id)
      return unless participation
      return if participation.play_time_credited?

      rank = @user.rank || @user.create_rank!(
        tier: :newbie,
        rating: GlobalRatingCalculator::DEFAULT_BASE_RATING
      )
      rank.update!(play_time_seconds: rank.play_time_seconds + duration)
      participation.update!(play_time_credited: true)
    end
  end
end
