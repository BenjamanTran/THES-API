# frozen_string_literal: true

module Users
  class FavoriteVenue
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      from_venue || from_location
    end

    private

    def from_venue
      GameParticipation
        .joins(game: :venue)
        .where(user_id: @user.id)
        .group('venues.id', 'venues.name')
        .order(Arel.sql('COUNT(*) DESC'))
        .limit(1)
        .pick('venues.name')
    end

    def from_location
      GameParticipation
        .joins(:game)
        .where(user_id: @user.id)
        .where.not(games: { location: [nil, ''] })
        .group('games.location')
        .order(Arel.sql('COUNT(*) DESC'))
        .limit(1)
        .pick('games.location')
    end
  end
end
