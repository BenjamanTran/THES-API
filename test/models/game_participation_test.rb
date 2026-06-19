# frozen_string_literal: true

require 'test_helper'

class GameParticipationTest < ActiveSupport::TestCase
  test 'host rated stars accepts half star decimals' do
    user = User.create!(
      name: 'Rated User',
      email: 'rated-user@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )
    host = User.create!(
      name: 'Host User',
      email: 'host-user@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )
    game = Game.create!(
      title: 'Rated Game',
      host: host,
      start_time: 1.day.from_now,
      end_time: 1.day.from_now + 2.hours,
      max_players: 4,
      min_tier: :newbie,
      max_tier: :professional
    )
    participation = GameParticipation.new(user: user, game: game, host_rated_stars: 2.5)

    assert participation.valid?
  end
end
