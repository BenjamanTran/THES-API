# frozen_string_literal: true

puts 'Seeding...'
now = Time.current

# ── 1. Test Users ────────────────────────────────────────────────
# Login: player1@example.com / password123  (dùng để test, là host)
# Login: player2@example.com / password123  (join cùng trận)
# ...

players = [
  { name: 'Tân',    email: 'player1@example.com', gender: 1 },
  { name: 'Minh',   email: 'player2@example.com', gender: 1 },
  { name: 'Hương',  email: 'player3@example.com', gender: 2 },
  { name: 'Đức',    email: 'player4@example.com', gender: 1 },
  { name: 'Linh',   email: 'player5@example.com', gender: 2 },
  { name: 'Khoa',   email: 'player6@example.com', gender: 1 },
  { name: 'Mai',    email: 'player7@example.com', gender: 2 },
  { name: 'Phong',  email: 'player8@example.com', gender: 1 },
  { name: 'Hải',    email: 'player9@example.com', gender: 1 },
  { name: 'Nga',    email: 'player10@example.com', gender: 2 },
  { name: 'Tuấn',   email: 'player11@example.com', gender: 1 },
  { name: 'Thảo',   email: 'player12@example.com', gender: 2 },
  { name: 'Bình',   email: 'player13@example.com', gender: 1 },
  { name: 'Lan',    email: 'player14@example.com', gender: 2 },
  { name: 'Quang',  email: 'player15@example.com', gender: 1 },
  { name: 'Yến',    email: 'player16@example.com', gender: 2 },
]

password_digest = BCrypt::Password.create('password123')

players.each do |p|
  User.find_or_create_by!(email: p[:email]) do |u|
    u.name = p[:name]
    u.gender = p[:gender]
    u.password_digest = password_digest
  end
end

# Admin / owner account
User.find_or_create_by!(email: 't16021999@gmail.com') do |u|
  u.name = 'Tân'
  u.gender = :male
  u.password_digest = BCrypt::Password.create('123123123')
end

users = User.where(email: players.map { |p| p[:email] }).index_by(&:email)
u1  = users['player1@example.com']  # Tân — host chính
u2  = users['player2@example.com']  # Minh
u3  = users['player3@example.com']  # Hương
u4  = users['player4@example.com']  # Đức
u5  = users['player5@example.com']  # Linh
u6  = users['player6@example.com']  # Khoa
u7  = users['player7@example.com']  # Mai
u8  = users['player8@example.com']  # Phong
u9  = users['player9@example.com']  # Hải
u10 = users['player10@example.com'] # Nga
u11 = users['player11@example.com'] # Tuấn
u12 = users['player12@example.com'] # Thảo
u13 = users['player13@example.com'] # Bình
u14 = users['player14@example.com'] # Lan
u15 = users['player15@example.com'] # Quang
u16 = users['player16@example.com'] # Yến

puts "Users: #{User.count}"

# ── 2. Ranks ────────────────────────────────────────────────────
rank_data = {
  u1  => { tier: :advanced,            rating: 1900, wins: 45, losses: 12 },
  u2  => { tier: :upper_intermediate,  rating: 1600, wins: 30, losses: 18 },
  u3  => { tier: :intermediate,        rating: 1300, wins: 22, losses: 20 },
  u4  => { tier: :advanced,            rating: 1850, wins: 40, losses: 15 },
  u5  => { tier: :lower_intermediate,  rating: 950,  wins: 15, losses: 25 },
  u6  => { tier: :upper_intermediate,  rating: 1700, wins: 35, losses: 10 },
  u7  => { tier: :beginner_plus,       rating: 600,  wins: 8,  losses: 30 },
  u8  => { tier: :intermediate,        rating: 1400, wins: 28, losses: 22 },
  u9  => { tier: :advanced,            rating: 1820, wins: 38, losses: 14 },
  u10 => { tier: :intermediate,        rating: 1350, wins: 20, losses: 18 },
  u11 => { tier: :upper_intermediate,  rating: 1550, wins: 25, losses: 20 },
  u12 => { tier: :lower_intermediate,  rating: 1050, wins: 12, losses: 22 },
  u13 => { tier: :intermediate,        rating: 1250, wins: 18, losses: 16 },
  u14 => { tier: :beginner_plus,       rating: 700,  wins: 10, losses: 28 },
  u15 => { tier: :upper_intermediate,  rating: 1650, wins: 32, losses: 12 },
  u16 => { tier: :lower_intermediate,  rating: 900,  wins: 14, losses: 24 },
}

rank_data.each do |user, data|
  user.rank || user.create_rank!(
    tier: data[:tier], rating: data[:rating], division: rand(1..3),
    wins: data[:wins], losses: data[:losses],
    matches_count: data[:wins] + data[:losses]
  )
end

puts "Ranks: #{Rank.count}"

# ── 3. Games ────────────────────────────────────────────────────
# Helper
def add_players(game, user_teams)
  user_teams.each do |user, team|
    game.game_participations.find_or_create_by!(user: user) do |gp|
      gp.team = team
    end
  end
  game.update_column(:players_count, game.game_participations.count)
end

def create_game(attrs)
  existing = Game.find_by(description: attrs[:description])
  return existing if existing

  game = Game.new(attrs)
  game.save!(validate: false)
  game
end

# ─── Game A: Doubles, ONGOING, 4 players, host=Tân ───
#     Trận đang chơi, đủ người, có thể tạo match
game_a = create_game(
  description: '[TEST] Doubles ongoing - đủ người',
  host: u1, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 30.minutes, end_time: now + 90.minutes,
  lat: 10.7626, lng: 106.6601, location: 'Galaxy Badminton Center',
  min_tier: :lower_intermediate, max_tier: :advanced,
  courts: [1, 2], min_price: 50_000, max_price: 80_000, players_count: 0
)
add_players(game_a, { u1 => :team_a, u2 => :team_b, u3 => :team_a, u4 => :team_b })

# Tạo 1 match đã kết thúc + 1 match đang chơi
if game_a.matches.empty?
  m1 = game_a.matches.create!(match_number: 1, status: :finished,
    team_a_score: 21, team_b_score: 18, winner_team: 'team_a',
    started_at: now - 25.minutes, finished_at: now - 10.minutes)
  m1.match_participations.create!(user: u1, team: :team_a, winner: true)
  m1.match_participations.create!(user: u3, team: :team_a, winner: true)
  m1.match_participations.create!(user: u2, team: :team_b, winner: false)
  m1.match_participations.create!(user: u4, team: :team_b, winner: false)

  m2 = game_a.matches.create!(match_number: 2, status: :ongoing,
    started_at: now - 5.minutes)
  m2.match_participations.create!(user: u1, team: :team_a)
  m2.match_participations.create!(user: u4, team: :team_a)
  m2.match_participations.create!(user: u2, team: :team_b)
  m2.match_participations.create!(user: u3, team: :team_b)
end

puts "Game A: #{game_a.description} (id=#{game_a.id}, #{game_a.matches.count} matches)"

# ─── Game B: Singles, FULL, 2 players, host=Tân ───
#     Chưa có match, host có thể tạo
game_b = create_game(
  description: '[TEST] Singles full - chưa có match',
  host: u1, match_type: :singles, max_players: 2, status: :full,
  start_time: now + 1.hour, end_time: now + 2.hours,
  lat: 10.7769, lng: 106.7009, location: 'Victory Sports',
  min_tier: :intermediate, max_tier: :advanced,
  min_price: 30_000, max_price: 50_000, players_count: 0
)
add_players(game_b, { u1 => :team_a, u6 => :team_b })

puts "Game B: #{game_b.description} (id=#{game_b.id})"

# ─── Game C: Doubles, OPEN, 3/4 players, host=Minh ───
#     Tân đã join, còn thiếu 1 slot
game_c = create_game(
  description: '[TEST] Doubles open - thiếu 1 người',
  host: u2, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 3.hours, end_time: now + 5.hours,
  lat: 10.7300, lng: 106.6500, location: 'Pro Badminton Center',
  min_tier: :beginner_plus, max_tier: :upper_intermediate,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_c, { u2 => :team_a, u1 => :team_b, u5 => :team_a })

puts "Game C: #{game_c.description} (id=#{game_c.id})"

# ─── Game D: Doubles, ONGOING, 4 players, host=Đức ───
#     Tân ko ở đây — để test view từ ngoài
game_d = create_game(
  description: '[TEST] Doubles ongoing - Tân ko join',
  host: u4, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 1.hour, end_time: now + 1.hour,
  lat: 10.8050, lng: 106.7100,
  min_tier: :newbie, max_tier: :semi_pro,
  min_price: 80_000, max_price: 120_000, players_count: 0
)
add_players(game_d, { u4 => :team_a, u6 => :team_b, u7 => :team_a, u8 => :team_b })

if game_d.matches.empty?
  m = game_d.matches.create!(match_number: 1, status: :finished,
    team_a_score: 15, team_b_score: 21, winner_team: 'team_b',
    started_at: now - 50.minutes, finished_at: now - 30.minutes)
  m.match_participations.create!(user: u4, team: :team_a, winner: false)
  m.match_participations.create!(user: u7, team: :team_a, winner: false)
  m.match_participations.create!(user: u6, team: :team_b, winner: true)
  m.match_participations.create!(user: u8, team: :team_b, winner: true)
end

puts "Game D: #{game_d.description} (id=#{game_d.id})"

# ─── Game E: Singles, OPEN, chưa ai join ngoài host ───
game_e = create_game(
  description: '[TEST] Singles open - chờ đối thủ',
  host: u3, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 2.hours, end_time: now + 3.hours,
  lat: 10.7626, lng: 106.6601, location: 'Galaxy Badminton Center',
  min_tier: :newbie, max_tier: :intermediate,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_e, { u3 => :team_a })

puts "Game E: #{game_e.description} (id=#{game_e.id})"

# ─── Game F: Doubles, FINISHED, đã xong hoàn toàn ───
game_f = create_game(
  description: '[TEST] Doubles finished - đã kết thúc',
  host: u1, match_type: :doubles, max_players: 4, status: :finished,
  start_time: now - 4.hours, end_time: now - 2.hours,
  lat: 10.7300, lng: 106.6500, location: 'Pro Badminton Center',
  min_tier: :intermediate, max_tier: :advanced,
  min_price: 60_000, max_price: 60_000, players_count: 0
)
add_players(game_f, { u1 => :team_a, u8 => :team_a, u2 => :team_b, u4 => :team_b })

if game_f.matches.empty?
  m1 = game_f.matches.create!(match_number: 1, status: :finished,
    team_a_score: 21, team_b_score: 19, winner_team: 'team_a',
    started_at: now - 3.5.hours, finished_at: now - 3.hours)
  m1.match_participations.create!(user: u1, team: :team_a, winner: true)
  m1.match_participations.create!(user: u8, team: :team_a, winner: true)
  m1.match_participations.create!(user: u2, team: :team_b, winner: false)
  m1.match_participations.create!(user: u4, team: :team_b, winner: false)

  m2 = game_f.matches.create!(match_number: 2, status: :finished,
    team_a_score: 18, team_b_score: 21, winner_team: 'team_b',
    started_at: now - 3.hours, finished_at: now - 2.5.hours)
  m2.match_participations.create!(user: u1, team: :team_a, winner: false)
  m2.match_participations.create!(user: u8, team: :team_a, winner: false)
  m2.match_participations.create!(user: u2, team: :team_b, winner: true)
  m2.match_participations.create!(user: u4, team: :team_b, winner: true)

  m3 = game_f.matches.create!(match_number: 3, status: :finished,
    team_a_score: 21, team_b_score: 15, winner_team: 'team_a',
    started_at: now - 2.5.hours, finished_at: now - 2.hours)
  m3.match_participations.create!(user: u1, team: :team_a, winner: true)
  m3.match_participations.create!(user: u8, team: :team_a, winner: true)
  m3.match_participations.create!(user: u2, team: :team_b, winner: false)
  m3.match_participations.create!(user: u4, team: :team_b, winner: false)
end

puts "Game F: #{game_f.description} (id=#{game_f.id}, #{game_f.matches.count} matches)"

# ─── Game G: Doubles, OPEN, 2/4, host=Khoa ───
game_g = create_game(
  description: 'Giao lưu cuối tuần, all levels',
  host: u6, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 4.hours, end_time: now + 6.hours,
  lat: 10.7650, lng: 106.6620, location: 'Saigon Badminton Club',
  min_tier: :newbie, max_tier: :advanced,
  min_price: 40_000, max_price: 60_000, players_count: 0
)
add_players(game_g, { u6 => :team_a, u7 => :team_b })
puts "Game G: #{game_g.description} (id=#{game_g.id})"

# ─── Game H: Singles, OPEN, 1/2, host=Phong ───
game_h = create_game(
  description: 'Tìm đối thủ singles, trình intermediate+',
  host: u8, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 5.hours, end_time: now + 6.hours,
  lat: 10.7800, lng: 106.6950, location: 'Victory Sports',
  min_tier: :intermediate, max_tier: :semi_pro,
  min_price: 50_000, max_price: 50_000, players_count: 0
)
add_players(game_h, { u8 => :team_a })
puts "Game H: #{game_h.description} (id=#{game_h.id})"

# ─── Game I: Doubles, OPEN, 3/4, host=Mai ───
game_i = create_game(
  description: 'Doubles tối nay, cần 1 người nữa',
  host: u1, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 15.minutes, end_time: now + 2.hours,
  lat: 10.8100, lng: 106.7050,
  min_tier: :beginner_plus, max_tier: :intermediate,
  min_price: 30_000, max_price: 30_000, players_count: 0
)
add_players(game_i, { u1 => :team_a, u5 => :team_b, u3 => :team_a, u7 => :team_b })
puts "Game I: #{game_i.description} (id=#{game_i.id})"

# ─── Game J: Doubles, ONGOING, 16 người, host=Tân ───
game_j = create_game(
  description: '[TEST] 16 người - giải đấu lớn',
  host: u1, match_type: :doubles, max_players: 16, status: :ongoing,
  start_time: now - 20.minutes, end_time: now + 3.hours,
  lat: 10.7626, lng: 106.6601, location: 'Galaxy Badminton Center',
  min_tier: :beginner_plus, max_tier: :advanced,
  courts: [1, 2, 3, 4], min_price: 40_000, max_price: 60_000, players_count: 0
)
add_players(game_j, {
  u1 => :team_a, u2 => :team_b, u3 => :team_a, u4 => :team_b,
  u5 => :team_a, u6 => :team_b, u7 => :team_a, u8 => :team_b,
  u9 => :team_a, u10 => :team_b, u11 => :team_a, u12 => :team_b,
  u13 => :team_a, u14 => :team_b, u15 => :team_a, u16 => :team_b,
})
if game_j.matches.empty?
  m1 = game_j.matches.create!(match_number: 1, status: :finished,
    team_a_score: 21, team_b_score: 17, winner_team: 'team_a',
    started_at: now - 18.minutes, finished_at: now - 8.minutes)
  m1.match_participations.create!(user: u1, team: :team_a, winner: true)
  m1.match_participations.create!(user: u3, team: :team_a, winner: true)
  m1.match_participations.create!(user: u2, team: :team_b, winner: false)
  m1.match_participations.create!(user: u4, team: :team_b, winner: false)

  m2 = game_j.matches.create!(match_number: 2, status: :ongoing,
    started_at: now - 5.minutes)
  m2.match_participations.create!(user: u5, team: :team_a)
  m2.match_participations.create!(user: u9, team: :team_a)
  m2.match_participations.create!(user: u6, team: :team_b)
  m2.match_participations.create!(user: u10, team: :team_b)

  m3 = game_j.matches.create!(match_number: 3, status: :ongoing,
    started_at: now - 3.minutes)
  m3.match_participations.create!(user: u7, team: :team_a)
  m3.match_participations.create!(user: u11, team: :team_a)
  m3.match_participations.create!(user: u8, team: :team_b)
  m3.match_participations.create!(user: u12, team: :team_b)
end

puts "Game J: #{game_j.description} (id=#{game_j.id}, #{game_j.matches.count} matches, 16 players)"

# ── Summary ─────────────────────────────────────────────────────
puts ''
puts '=== Seed Summary ==='
puts "Users:       #{User.count}"
puts "Games:       #{Game.count}"
puts "Matches:     #{Match.count}"
puts ''
puts '=== Test Accounts ==='
puts 'Email: player1@example.com  Pass: password123  (Tân - host Game A, B, F)'
puts 'Email: player2@example.com  Pass: password123  (Minh - host Game C)'
puts ''
puts '=== Test Games ==='
puts "Game A (id=#{game_a.id}): Doubles ONGOING, 4 người, 2 matches (1 finished + 1 ongoing)"
puts "Game B (id=#{game_b.id}): Singles FULL, 2 người, chưa có match → test tạo match"
puts "Game C (id=#{game_c.id}): Doubles OPEN, 3/4 người → test join"
puts "Game D (id=#{game_d.id}): Doubles ONGOING, Tân ko join → test view ngoài"
puts "Game E (id=#{game_e.id}): Singles OPEN, chờ đối thủ → test join"
puts "Game F (id=#{game_f.id}): Doubles FINISHED, 3 matches → test xem kết quả"
puts "Game G (id=#{game_g.id}): Doubles OPEN, 2/4 → tìm trận"
puts "Game H (id=#{game_h.id}): Singles OPEN, 1/2 → tìm trận"
puts "Game I (id=#{game_i.id}): Doubles OPEN, 3/4 → tìm trận"
puts ''
puts '=== Cách test ==='
puts '1. Login player1@example.com → Tab "Trận của tôi" → thấy Game A,B,C'
puts '2. Bấm vào Game A (ongoing) → thấy matches, tạo match mới, kết thúc match'
puts '3. Tab "Tìm trận" → thấy Game C,E,G,H,I (status=open)'
puts '4. Bấm "Đã qua" ở "Trận của tôi" → thấy Game F (finished, 3 matches)'
puts '===================='
