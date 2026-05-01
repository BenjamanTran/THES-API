# Seeds

puts "Creating users..."

user1 = User.find_or_create_by!(email: "host@example.com") do |u|
  u.name = "Host User"
end

user2 = User.find_or_create_by!(email: "player1@example.com") do |u|
  u.name = "Player One"
end

user3 = User.find_or_create_by!(email: "player2@example.com") do |u|
  u.name = "Player Two"
end

user4 = User.find_or_create_by!(email: "player3@example.com") do |u|
  u.name = "Player Three"
end

puts "Creating ranks..."

[
  { user: user1, rating: 1300, tier: :gold, division: 2 },
  { user: user2, rating: 800, tier: :silver, division: 3 },
  { user: user3, rating: 2000, tier: :diamond, division: 1 },
  { user: user4, rating: 400, tier: :bronze, division: 2 }
].each do |attrs|
  Rank.find_or_create_by!(user: attrs[:user]) do |r|
    r.rating = attrs[:rating]
    r.tier = attrs[:tier]
    r.division = attrs[:division]
  end
end

puts "Seeded #{User.count} users with ranks."

puts 'Creating games...'

hosts = [user1, user2, user3, user4]

games_data = [
  { lat: 10.7769, lng: 106.7009, match_type: :doubles, min_tier: :bronze, max_tier: :gold, offset_hours: 1 },
  { lat: 10.7800, lng: 106.6950, match_type: :singles, min_tier: :silver, max_tier: :platinum, offset_hours: 2 },
  { lat: 10.7620, lng: 106.6820, match_type: :doubles, min_tier: :bronze, max_tier: :silver, offset_hours: 3 },
  { lat: 10.8010, lng: 106.7150, match_type: :singles, min_tier: :gold, max_tier: :diamond, offset_hours: 4 },
  { lat: 10.7550, lng: 106.6600, match_type: :doubles, min_tier: :bronze, max_tier: :master, offset_hours: 5 },
  { lat: 10.7900, lng: 106.7100, match_type: :singles, min_tier: :silver, max_tier: :gold, offset_hours: 6 },
  { lat: 10.7700, lng: 106.6900, match_type: :doubles, min_tier: :platinum, max_tier: :diamond, offset_hours: 8 },
  { lat: 10.7650, lng: 106.7050, match_type: :singles, min_tier: :bronze, max_tier: :platinum, offset_hours: 12 },
  { lat: 10.8100, lng: 106.7200, match_type: :doubles, min_tier: :gold, max_tier: :master, offset_hours: 24 },
  { lat: 10.7450, lng: 106.6750, match_type: :singles, min_tier: :bronze, max_tier: :gold, offset_hours: 48 }
]

games_data.each_with_index do |data, i|
  host = hosts[i % hosts.size]
  max_players = data[:match_type] == :singles ? 2 : 4
  start = Time.current + data[:offset_hours].hours

  game = Game.create!(
    start_time: start,
    end_time: start + 1.hour,
    lat: data[:lat],
    lng: data[:lng],
    match_type: data[:match_type],
    min_tier: data[:min_tier],
    max_tier: data[:max_tier],
    max_players: max_players,
    host: host,
    players_count: 1,
    status: :open
  )
  game.game_participations.create!(user: host, team: :team_a)
  puts "  Game ##{game.id}: #{data[:match_type]} at (#{data[:lat]}, #{data[:lng]}) starting in #{data[:offset_hours]}h"
end

puts "Seeded #{Game.count} games."
