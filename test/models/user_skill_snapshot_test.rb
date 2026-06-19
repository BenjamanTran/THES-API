# frozen_string_literal: true

require 'test_helper'

class UserSkillSnapshotTest < ActiveSupport::TestCase
  test 'upsert_for_month stores one monthly snapshot and derives declared rank' do
    user = User.create!(
      name: 'Nguyen Van A',
      email: 'a@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    first = UserSkillSnapshot.upsert_for_month!(
      user: user,
      month: Date.new(2026, 6, 1),
      tier: 'intermediate',
      scores: {
        attack: 8,
        defense: 7,
        technique: 6,
        agility: 6,
        footwork: 7,
        stamina: 5
      }
    )

    second = UserSkillSnapshot.upsert_for_month!(
      user: user,
      month: Date.new(2026, 6, 18),
      tier: 'intermediate',
      scores: {
        attack: 8,
        defense: 7,
        technique: 7,
        agility: 7,
        footwork: 7,
        stamina: 6
      }
    )

    assert_equal first.id, second.id
    assert_equal 1, user.skill_snapshots.count
    assert_equal Date.new(2026, 6, 1), second.month
    assert_equal 7.0, second.overall_score
    assert_equal Rank.tiers['intermediate'], second.declared_tier
    assert_equal 3.5, second.computed_stars
    assert_equal 1750, second.declared_rating

    user.reload
    assert_equal Rank.tiers['intermediate'], user.rank.declared_tier
    assert_equal 1750, user.rank.declared_rating
  end

  test 'computed stars are decimal and do not round uneven skills up to five stars' do
    user = User.create!(
      name: 'Nguyen Van C',
      email: 'c@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    snapshot = UserSkillSnapshot.upsert_for_month!(
      user: user,
      month: Date.new(2026, 6, 1),
      tier: 'advanced',
      scores: {
        attack: 10,
        defense: 10,
        technique: 10,
        agility: 10,
        footwork: 10,
        stamina: 1
      }
    )

    assert_equal 8.5, snapshot.overall_score
    assert_equal 4.25, snapshot.computed_stars
    assert_equal 2825, snapshot.declared_rating
  end

  test 'payload should derive computed stars from overall score even if stored value is stale' do
    user = User.create!(
      name: 'Nguyen Van D',
      email: 'd@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    snapshot = UserSkillSnapshot.upsert_for_month!(
      user: user,
      month: Date.new(2026, 6, 1),
      tier: 'advanced',
      scores: {
        attack: 10,
        defense: 10,
        technique: 10,
        agility: 10,
        footwork: 10,
        stamina: 8
      }
    )

    snapshot.update_column(:computed_stars, 4.0)

    payload = Users::SkillProfilePayload.call(user: user)
    assert_equal 4.85, payload[:skill_radar][:computed_stars]
  end

  test 'default skill scores start at two and a half stars' do
    assert_equal 2.5, UserSkillSnapshot.computed_stars_from_overall(5)
  end

  test 'scores must be integers from 1 to 10' do
    user = User.create!(
      name: 'Nguyen Van B',
      email: 'b@example.com',
      password: 'password123',
      email_verified_at: Time.current
    )

    snapshot = UserSkillSnapshot.new(
      user: user,
      month: Date.new(2026, 6, 1),
      declared_tier: Rank.tiers['intermediate'],
      computed_stars: 3.0,
      declared_rating: 1700,
      attack: 8,
      defense: 7,
      technique: 0,
      agility: 6,
      footwork: 7,
      stamina: 5
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:technique], 'is not included in the list'
  end
end
