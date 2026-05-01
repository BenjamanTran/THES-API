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
