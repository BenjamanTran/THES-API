# frozen_string_literal: true

require 'test_helper'

module Games
  class PlaceholderServiceTest < ActiveSupport::TestCase
    test 'create stores half star placeholder rating' do
      host = User.create!(
        name: 'Host',
        email: 'host-placeholder@example.com',
        password: 'password123',
        email_verified_at: Time.current
      )
      game = Game.create!(
        title: 'Test Game',
        host: host,
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 2.hours,
        max_players: 4,
        min_tier: :newbie,
        max_tier: :professional
      )

      result = PlaceholderService.new(
        user: host,
        game: game,
        params: { name: 'Bạn tạm', gender: 'male', tier: 'intermediate', stars: 2.5 }
      ).create

      assert result.success?

      participation = game.game_participations.find_by!(user: result.data[:player])
      assert_equal 2.5, participation.host_rated_stars
      assert_equal 1650, result.data[:player].rank.rating
    end

    test 'create defaults placeholder rating to two and a half stars' do
      host = User.create!(
        name: 'Host Default',
        email: 'host-placeholder-default@example.com',
        password: 'password123',
        email_verified_at: Time.current
      )
      game = Game.create!(
        title: 'Default Game',
        host: host,
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 2.hours,
        max_players: 4,
        min_tier: :newbie,
        max_tier: :professional
      )

      result = PlaceholderService.new(
        user: host,
        game: game,
        params: { name: 'Bạn tạm', gender: 'male', tier: 'intermediate' }
      ).create

      assert result.success?

      participation = game.game_participations.find_by!(user: result.data[:player])
      assert_equal 2.5, participation.host_rated_stars
      assert_equal 1650, result.data[:player].rank.rating
    end
  end
end
