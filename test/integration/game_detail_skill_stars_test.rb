# frozen_string_literal: true

require 'test_helper'

class GameDetailSkillStarsTest < ActionDispatch::IntegrationTest
  test 'game detail payload preserves decimal host rated stars' do
    host = User.create!(
      name: 'Host',
      email: 'game-detail-host@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )
    player = User.create!(
      name: 'Player',
      email: 'game-detail-player@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )
    game = Game.create!(
      title: 'Detail Game',
      host: host,
      start_time: 1.day.from_now,
      end_time: 1.day.from_now + 2.hours,
      match_type: :doubles,
      max_players: 4,
      min_tier: :newbie,
      max_tier: :professional
    )
    GameParticipation.create!(
      game: game,
      user: player,
      team: :team_a,
      role: :player,
      host_rated_tier: :hr_advanced,
      host_rated_stars: 4.1
    )

    get "/api/v1/games/#{game.id}", headers: { 'X-User-Id' => host.id.to_s }

    assert_response :success

    player_json = response.parsed_body['players'].find { |p| p['id'] == player.id }
    assert_equal 4.1, player_json['host_rated_stars']
  end
end
