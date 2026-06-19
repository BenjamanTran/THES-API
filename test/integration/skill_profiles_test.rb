# frozen_string_literal: true

require 'test_helper'

class SkillProfilesTest < ActionDispatch::IntegrationTest
  test 'signed in user can save skill radar scores and receive refreshed profile payload' do
    user = User.create!(
      name: 'Tran Thi A',
      email: 'tran@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    travel_to Time.zone.local(2026, 6, 18, 10, 0, 0) do
      patch '/api/v1/me/skills',
            params: {
              tier: 'advanced',
              scores: {
                attack: 8,
                defense: 7,
                technique: 6,
                agility: 6,
                footwork: 7,
                stamina: 5
              }
            },
            headers: { 'X-User-Id' => user.id.to_s },
            as: :json
    end

    assert_response :success

    body = response.parsed_body
    radar = body.dig('profile', 'skill_radar')

    assert_equal Date.new(2026, 6, 1).iso8601, radar['month']
    assert_equal 6.5, radar['overall_score']
    assert_equal 'advanced', radar['declared_tier']
    assert_equal 3.25, radar['computed_stars']
    assert_equal 2725, radar['declared_rating']
    assert_equal 6, radar['axes'].length
    assert_equal %w[attack defense technique agility footwork stamina], radar['axes'].pluck('key')
    assert_equal 'Kỹ thuật', radar['axes'].find { |axis| axis['key'] == 'technique' }['label']
    assert_equal 'advanced', body.dig('user', 'declared_rank', 'tier')
    assert_equal 2725, body.dig('user', 'declared_rank', 'rating')

    get '/api/v1/me', headers: { 'X-User-Id' => user.id.to_s }

    assert_response :success
    assert_equal 1, response.parsed_body.dig('profile', 'skill_history').length
  end

  test 'skill scores outside 1 to 10 are rejected' do
    user = User.create!(
      name: 'Tran Thi B',
      email: 'tranb@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    patch '/api/v1/me/skills',
          params: {
            tier: 'advanced',
            scores: {
              attack: 8,
              defense: 7,
              technique: 11,
              agility: 6,
              footwork: 7,
              stamina: 5
            }
          },
          headers: { 'X-User-Id' => user.id.to_s },
          as: :json

    assert_response :unprocessable_content
    assert_match(/Technique/, response.parsed_body['errors'].join(', '))
  end

  test 'all six skill scores are required' do
    user = User.create!(
      name: 'Tran Thi C',
      email: 'tranc@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    patch '/api/v1/me/skills',
          params: {
            tier: 'advanced',
            scores: {
              attack: 8,
              defense: 7,
              agility: 6,
              footwork: 7,
              stamina: 5
            }
          },
          headers: { 'X-User-Id' => user.id.to_s },
          as: :json

    assert_response :unprocessable_content
    assert_match(/Technique/, response.parsed_body['errors'].join(', '))
  end
end
