# frozen_string_literal: true

puts 'Seeding...'

# ── 1. Users (100) ──────────────────────────────────────────────
now = Time.current

user_rows = 100.times.map do |i|
  { name: "Player #{i + 1}", email: "player#{i + 1}@example.com", created_at: now, updated_at: now }
end
User.insert_all(user_rows)

user_ids = User.pluck(:id)
puts "Created #{user_ids.size} users."

# ── 2. Ranks ────────────────────────────────────────────────────
TIERS = Rank.tiers.keys
RATING_RANGES = {
  'newbie' => 0..399,
  'beginner_plus' => 400..799,
  'lower_intermediate' => 800..1199,
  'intermediate' => 1200..1499,
  'upper_intermediate' => 1500..1799,
  'advanced' => 1800..2099,
  'semi_pro' => 2100..2399,
  'professional' => 2400..2700
}.freeze

existing_rank_user_ids = Rank.pluck(:user_id)
rank_rows = (user_ids - existing_rank_user_ids).map do |uid|
  tier = TIERS.sample
  range = RATING_RANGES[tier] || (0..799)
  { user_id: uid, tier: Rank.tiers[tier], rating: rand(range), division: rand(1..3),
    wins: 0, losses: 0, matches_count: 0, created_at: now, updated_at: now }
end
Rank.insert_all(rank_rows) if rank_rows.any?
puts "Created #{rank_rows.size} ranks."

# ── 3. Games (1000) ─────────────────────────────────────────────
CLUSTERS = [
  { name: 'District 1', lat: 10.7626, lng: 106.6601 },
  { name: 'District 2', lat: 10.7769, lng: 106.7009 },
  { name: 'District 7', lat: 10.7300, lng: 106.6500 }
].freeze

DESCRIPTIONS = [
  'Friendly match, need 1 more player',
  'Intermediate level, casual play',
  'Looking for players around this area',
  'Evening match, join if available',
  'Competitive game, good stamina required',
  'Beginners welcome, just for fun',
  'Quick match after work, all levels',
  'Weekend game, bring your own racket',
  'Doubles match, need a partner',
  'Serious game, high intensity'
].freeze

MATCH_TYPES = { 'singles' => 0, 'doubles' => 1 }.freeze
STATUSES = { 'open' => 0, 'full' => 1 }.freeze

game_rows = []
participation_rows = []

1000.times do |i|
  cluster = CLUSTERS.sample
  lat = (cluster[:lat] + rand(-0.02..0.02)).round(7)
  lng = (cluster[:lng] + rand(-0.02..0.02)).round(7)

  start_time = now + rand(1..72).hours + rand(0..59).minutes
  end_time = start_time + rand(60..90).minutes

  min_tier = rand(0..5)
  max_tier = [min_tier + rand(0..2), 7].min

  match_type_key = %w[singles doubles].sample
  max_players = match_type_key == 'singles' ? 2 : 4
  players_count = rand(1..max_players)

  status = rand < 0.8 ? 0 : 1 # 80% open, 20% full
  status = 1 if players_count == max_players

  host_id = user_ids.sample

  game_rows << {
    start_time: start_time, end_time: end_time,
    lat: lat, lng: lng,
    match_type: MATCH_TYPES[match_type_key],
    min_tier: min_tier, max_tier: max_tier,
    max_players: max_players, players_count: players_count,
    status: status, host_id: host_id,
    description: DESCRIPTIONS.sample,
    created_at: now, updated_at: now
  }
end

# Batch insert games
result = Game.insert_all(game_rows)
puts "Created #{result.count} games."

# ── 4. Participations ───────────────────────────────────────────
games = Game.select(:id, :host_id, :players_count, :max_players).where('id > ?', 0).to_a

games.each do |game|
  participants = [game.host_id]

  remaining = game.players_count - 1
  if remaining.positive?
    others = (user_ids - [game.host_id]).sample(remaining)
    participants.concat(others)
  end

  participants.each_with_index do |uid, idx|
    team = idx.even? ? 0 : 1
    participation_rows << {
      user_id: uid, game_id: game.id, team: team,
      winner: false, created_at: now, updated_at: now
    }
  end
end

GameParticipation.insert_all(participation_rows) if participation_rows.any?
puts "Created #{participation_rows.size} participations."

puts 'Seed complete.'
