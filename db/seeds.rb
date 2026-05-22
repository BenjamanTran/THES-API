# frozen_string_literal: true

require_relative 'seeds/rating_helpers'

puts 'Seeding...'
now = Time.current

# ── 1. Test Users ────────────────────────────────────────────────
# Login: player1@example.com / password123  (dùng để test, là host)
# Login: player2@example.com / password123  (join cùng trận)
# ...

players = [
  { name: 'Tân',        email: 'player1@example.com',  gender: 1 },
  { name: 'Minh',       email: 'player2@example.com',  gender: 1 },
  { name: 'Hương',      email: 'player3@example.com',  gender: 2 },
  { name: 'Đức',        email: 'player4@example.com',  gender: 1 },
  { name: 'Linh',       email: 'player5@example.com',  gender: 2 },
  { name: 'Khoa',       email: 'player6@example.com',  gender: 1 },
  { name: 'Mai',        email: 'player7@example.com',  gender: 2 },
  { name: 'Phong',      email: 'player8@example.com',  gender: 1 },
  { name: 'Hải',        email: 'player9@example.com',  gender: 1 },
  { name: 'Nga',        email: 'player10@example.com', gender: 2 },
  { name: 'Tuấn',       email: 'player11@example.com', gender: 1 },
  { name: 'Thảo',       email: 'player12@example.com', gender: 2 },
  { name: 'Bình',       email: 'player13@example.com', gender: 1 },
  { name: 'Lan',        email: 'player14@example.com', gender: 2 },
  { name: 'Quang',      email: 'player15@example.com', gender: 1 },
  { name: 'Yến',        email: 'player16@example.com', gender: 2 },
  { name: 'Trung',      email: 'player17@example.com', gender: 1 },
  { name: 'Thanh',      email: 'player18@example.com', gender: 2 },
  { name: 'Hoàng',      email: 'player19@example.com', gender: 1 },
  { name: 'Nhung',      email: 'player20@example.com', gender: 2 },
  { name: 'Dũng',       email: 'player21@example.com', gender: 1 },
  { name: 'Trang',      email: 'player22@example.com', gender: 2 },
  { name: 'Long',       email: 'player23@example.com', gender: 1 },
  { name: 'Hà',         email: 'player24@example.com', gender: 2 },
  { name: 'Việt',       email: 'player25@example.com', gender: 1 },
  { name: 'Oanh',       email: 'player26@example.com', gender: 2 },
  { name: 'Nam',        email: 'player27@example.com', gender: 1 },
  { name: 'Hiền',       email: 'player28@example.com', gender: 2 },
  { name: 'Cường',      email: 'player29@example.com', gender: 1 },
  { name: 'Phương',     email: 'player30@example.com', gender: 2 },
]

password_digest = BCrypt::Password.create('password123')

players.each do |p|
  User.find_or_create_by!(email: p[:email]) do |u|
    u.name = p[:name]
    u.gender = p[:gender]
    u.password_digest = password_digest
  end
end

admin = User.find_or_create_by!(email: 't16021999@gmail.com') do |u|
  u.name = 'Tân Admin'
  u.gender = :male
  u.password_digest = BCrypt::Password.create('123123123')
end

users = User.where(email: players.map { |p| p[:email] }).index_by(&:email)
u1  = users['player1@example.com']
u2  = users['player2@example.com']
u3  = users['player3@example.com']
u4  = users['player4@example.com']
u5  = users['player5@example.com']
u6  = users['player6@example.com']
u7  = users['player7@example.com']
u8  = users['player8@example.com']
u9  = users['player9@example.com']
u10 = users['player10@example.com']
u11 = users['player11@example.com']
u12 = users['player12@example.com']
u13 = users['player13@example.com']
u14 = users['player14@example.com']
u15 = users['player15@example.com']
u16 = users['player16@example.com']
u17 = users['player17@example.com']
u18 = users['player18@example.com']
u19 = users['player19@example.com']
u20 = users['player20@example.com']
u21 = users['player21@example.com']
u22 = users['player22@example.com']
u23 = users['player23@example.com']
u24 = users['player24@example.com']
u25 = users['player25@example.com']
u26 = users['player26@example.com']
u27 = users['player27@example.com']
u28 = users['player28@example.com']
u29 = users['player29@example.com']
u30 = users['player30@example.com']

puts "Users: #{User.count}"

# ── 2. Ranks (tier + stars → rating; declared_*; global sync via host skill + W/L) ──
# Stars map to Rank::TIER_BASE + (stars-1)×100 — same as production Rank / FE rating-stars.

RANK_PROFILES = {
  'player1@example.com'  => { tier: :advanced,            stars: 4, wins: 28, losses: 14 },
  'player2@example.com'  => { tier: :upper_intermediate,  stars: 3, wins: 22, losses: 18 },
  'player3@example.com'  => { tier: :intermediate,          stars: 3, wins: 18, losses: 20 },
  'player4@example.com'  => { tier: :advanced,              stars: 3, wins: 24, losses: 16 },
  'player5@example.com'  => { tier: :lower_intermediate,    stars: 4, wins: 12, losses: 22 },
  'player6@example.com'  => { tier: :upper_intermediate,    stars: 4, wins: 26, losses: 12 },
  'player7@example.com'  => { tier: :beginner_plus,         stars: 2, wins: 6,  losses: 24 },
  'player8@example.com'  => { tier: :intermediate,          stars: 4, wins: 20, losses: 18 },
  'player9@example.com'  => { tier: :advanced,              stars: 3, wins: 30, losses: 12 },
  'player10@example.com' => { tier: :intermediate,          stars: 2, wins: 14, losses: 16 },
  'player11@example.com' => { tier: :upper_intermediate,    stars: 3, wins: 19, losses: 17 },
  'player12@example.com' => { tier: :lower_intermediate,    stars: 3, wins: 10, losses: 20 },
  'player13@example.com' => { tier: :intermediate,          stars: 3, wins: 16, losses: 14 },
  'player14@example.com' => { tier: :beginner_plus,         stars: 3, wins: 8,  losses: 26 },
  'player15@example.com' => { tier: :upper_intermediate,    stars: 4, wins: 25, losses: 11 },
  'player16@example.com' => { tier: :lower_intermediate,    stars: 2, wins: 9,  losses: 21 },
  'player17@example.com' => { tier: :semi_pro,              stars: 3, wins: 35, losses: 8 },
  'player18@example.com' => { tier: :advanced,              stars: 4, wins: 32, losses: 10 },
  'player19@example.com' => { tier: :intermediate,          stars: 4, wins: 17, losses: 15 },
  'player20@example.com' => { tier: :beginner_plus,         stars: 2, wins: 4,  losses: 28 },
  'player21@example.com' => { tier: :upper_intermediate,    stars: 4, wins: 27, losses: 13 },
  'player22@example.com' => { tier: :lower_intermediate,    stars: 3, wins: 11, losses: 19 },
  'player23@example.com' => { tier: :advanced,              stars: 3, wins: 29, losses: 11 },
  'player24@example.com' => { tier: :intermediate,          stars: 3, wins: 15, losses: 17 },
  'player25@example.com' => { tier: :semi_pro,              stars: 4, wins: 38, losses: 7 },
  'player26@example.com' => { tier: :newbie,                stars: 3, wins: 2,  losses: 16 },
  'player27@example.com' => { tier: :upper_intermediate,    stars: 3, wins: 21, losses: 15 },
  'player28@example.com' => { tier: :lower_intermediate,    stars: 4, wins: 13, losses: 18 },
  'player29@example.com' => { tier: :professional,          stars: 3, wins: 42, losses: 6 },
  'player30@example.com' => { tier: :intermediate,          stars: 2, wins: 12, losses: 14 },
  't16021999@gmail.com'    => { tier: :advanced,            stars: 3, wins: 24, losses: 12 },
}.freeze

(players.map { |p| p[:email] } + ['t16021999@gmail.com']).each do |email|
  user = User.find_by!(email: email)
  profile = RANK_PROFILES[email] || { tier: :newbie, stars: 3, wins: 0, losses: 0 }
  Seeds::RatingHelpers.upsert_player_rank!(user, **profile, now: now)
end

puts "Ranks: #{Rank.count}"

# ── 3. Venues ────────────────────────────────────────────────────
venue_data = [
  # HCM venues
  { name: 'Galaxy Badminton Center',     address: '123 Nguyễn Thị Minh Khai, Q.1',   city: 'HCM', district: 'Quận 1',       lat: 10.7726, lng: 106.6901 },
  { name: 'Victory Sports',             address: '456 Điện Biên Phủ, Bình Thạnh',    city: 'HCM', district: 'Bình Thạnh',   lat: 10.7969, lng: 106.7109 },
  { name: 'Pro Badminton Center',        address: '789 Nguyễn Hữu Cảnh, Q.Bình Thạnh', city: 'HCM', district: 'Bình Thạnh', lat: 10.7900, lng: 106.7200 },
  { name: 'Saigon Badminton Club',       address: '321 Trần Hưng Đạo, Q.5',          city: 'HCM', district: 'Quận 5',       lat: 10.7550, lng: 106.6720 },
  { name: 'Tân Bình Sports Center',      address: '55 Hoàng Hoa Thám, Tân Bình',     city: 'HCM', district: 'Tân Bình',     lat: 10.8020, lng: 106.6530 },
  { name: 'Phú Nhuận Badminton',         address: '88 Phan Đình Phùng, Phú Nhuận',   city: 'HCM', district: 'Phú Nhuận',    lat: 10.7990, lng: 106.6810 },
  { name: 'Quận 7 Sports Club',          address: '234 Nguyễn Thị Thập, Q.7',        city: 'HCM', district: 'Quận 7',       lat: 10.7380, lng: 106.7220 },
  { name: 'Thủ Đức Badminton Arena',     address: '567 Võ Văn Ngân, TP Thủ Đức',     city: 'HCM', district: 'TP Thủ Đức',   lat: 10.8500, lng: 106.7710 },
  { name: 'Gò Vấp Sport Center',         address: '99 Nguyễn Oanh, Gò Vấp',          city: 'HCM', district: 'Gò Vấp',       lat: 10.8380, lng: 106.6680 },
  { name: 'Quận 2 Badminton',            address: '45 Thảo Điền, TP Thủ Đức',        city: 'HCM', district: 'TP Thủ Đức',   lat: 10.8060, lng: 106.7350 },
  # HN venues
  { name: 'Hà Nội Badminton Center',     address: '12 Trần Phú, Ba Đình',            city: 'HN',  district: 'Ba Đình',       lat: 21.0340, lng: 105.8380 },
  { name: 'Cầu Giấy Sports Club',        address: '78 Xuân Thủy, Cầu Giấy',          city: 'HN',  district: 'Cầu Giấy',     lat: 21.0370, lng: 105.7850 },
  { name: 'Thanh Xuân Badminton',         address: '156 Nguyễn Trãi, Thanh Xuân',     city: 'HN',  district: 'Thanh Xuân',    lat: 20.9960, lng: 105.8100 },
  { name: 'Hoàn Kiếm Arena',             address: '30 Hàng Bài, Hoàn Kiếm',          city: 'HN',  district: 'Hoàn Kiếm',     lat: 21.0240, lng: 105.8510 },
  { name: 'Long Biên Sports Center',      address: '88 Nguyễn Văn Cừ, Long Biên',     city: 'HN',  district: 'Long Biên',     lat: 21.0470, lng: 105.8780 },
  { name: 'Hà Đông Badminton Club',       address: '200 Quang Trung, Hà Đông',        city: 'HN',  district: 'Hà Đông',       lat: 20.9720, lng: 105.7780 },
  { name: 'Đống Đa Badminton',            address: '45 Tây Sơn, Đống Đa',             city: 'HN',  district: 'Đống Đa',       lat: 21.0120, lng: 105.8260 },
  { name: 'Nam Từ Liêm Sports',           address: '99 Mễ Trì, Nam Từ Liêm',          city: 'HN',  district: 'Nam Từ Liêm',   lat: 21.0130, lng: 105.7690 },
]

venues = {}
venue_data.each do |v|
  venue = Venue.find_or_create_by!(name: v[:name]) do |vn|
    vn.address    = v[:address]
    vn.city       = v[:city]
    vn.district   = v[:district]
    vn.lat        = v[:lat]
    vn.lng        = v[:lng]
    vn.verified   = false
  end
  venues[v[:name]] = venue
end

puts "Venues: #{Venue.count}"

# ── 4. Games ────────────────────────────────────────────────────
Game.where('description LIKE ?', '[TEST]%').destroy_all
puts "Cleaned old test games"

def add_players(game, user_teams)
  user_teams.each do |user, team|
    game.game_participations.find_or_create_by!(user: user) do |gp|
      gp.team = team
    end
  end
  game.update_column(:players_count, game.game_participations.count)
end

def create_game(attrs)
  game = Game.new(attrs)
  game.save!(validate: false)
  game
end

# ========== HCM Games ==========

# ─── Game A: Doubles, ONGOING, 4 players, host=Tân ───
v = venues['Galaxy Badminton Center']
game_a = create_game(
  title: 'Giao lưu tối thứ 4', description: '[TEST] Doubles ongoing - đủ người',
  host: u1, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 30.minutes, end_time: now + 90.minutes,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :lower_intermediate, max_tier: :advanced,
  courts: [1, 2], min_price: 50_000, max_price: 80_000, players_count: 0
)
add_players(game_a, { u1 => :team_a, u2 => :team_b, u3 => :team_a, u4 => :team_b })

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
puts "Game A: #{game_a.title} (id=#{game_a.id})"

# ─── Game B: Singles, FULL ───
v = venues['Victory Sports']
game_b = create_game(
  description: '[TEST] Singles full - chưa có match',
  host: u1, match_type: :singles, max_players: 2, status: :full,
  start_time: now + 1.hour, end_time: now + 2.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :intermediate, max_tier: :advanced,
  min_price: 30_000, max_price: 50_000, players_count: 0
)
add_players(game_b, { u1 => :team_a, u6 => :team_b })
puts "Game B (id=#{game_b.id})"

# ─── Game C: Doubles, OPEN, 3/4 ───
v = venues['Pro Badminton Center']
game_c = create_game(
  title: 'Doubles chiều Q.Bình Thạnh', description: '[TEST] Doubles open - thiếu 1 người',
  host: u2, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 3.hours, end_time: now + 5.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :upper_intermediate,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_c, { u2 => :team_a, u1 => :team_b, u5 => :team_a })
puts "Game C (id=#{game_c.id})"

# ─── Game D: Doubles, ONGOING, Tân ko join ───
v = venues['Tân Bình Sports Center']
game_d = create_game(
  title: 'Luyện tập buổi chiều', description: '[TEST] Doubles ongoing - Tân ko join',
  host: u4, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 1.hour, end_time: now + 1.hour,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
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
puts "Game D (id=#{game_d.id})"

# ─── Game E: Singles, OPEN, chờ đối thủ ───
v = venues['Galaxy Badminton Center']
game_e = create_game(
  description: '[TEST] Singles open - chờ đối thủ',
  host: u3, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 2.hours, end_time: now + 3.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :newbie, max_tier: :intermediate,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_e, { u3 => :team_a })
puts "Game E (id=#{game_e.id})"

# ─── Game F: Doubles, FINISHED ───
v = venues['Pro Badminton Center']
game_f = create_game(
  title: 'Giải cuối tuần đã kết thúc', description: '[TEST] Doubles finished - đã kết thúc',
  host: u1, match_type: :doubles, max_players: 4, status: :finished,
  start_time: now - 4.hours, end_time: now - 2.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
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
puts "Game F (id=#{game_f.id})"

# ─── Game G: Doubles, OPEN, 2/4, host=Khoa ───
v = venues['Saigon Badminton Club']
game_g = create_game(
  title: 'Giao lưu cuối tuần Q.5', description: '[TEST] Giao lưu cuối tuần, all levels',
  host: u6, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 4.hours, end_time: now + 6.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :newbie, max_tier: :advanced,
  min_price: 40_000, max_price: 60_000, players_count: 0
)
add_players(game_g, { u6 => :team_a, u7 => :team_b })
puts "Game G (id=#{game_g.id})"

# ─── Game H: Singles, OPEN, host=Phong ───
v = venues['Victory Sports']
game_h = create_game(
  title: 'Tìm đối Singles trình cao', description: '[TEST] Tìm đối thủ singles, trình intermediate+',
  host: u8, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 5.hours, end_time: now + 6.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :intermediate, max_tier: :semi_pro,
  min_price: 50_000, max_price: 50_000, players_count: 0
)
add_players(game_h, { u8 => :team_a })
puts "Game H (id=#{game_h.id})"

# ─── Game I: Doubles, ONGOING, host=admin ───
v = venues['Phú Nhuận Badminton']
game_i = create_game(
  title: 'Doubles Phú Nhuận tối nay', description: '[TEST] Doubles tối nay',
  host: u1, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 15.minutes, end_time: now + 2.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :intermediate,
  min_price: 30_000, max_price: 30_000, players_count: 0
)
add_players(game_i, { u1 => :team_a, u5 => :team_b, u3 => :team_a, u7 => :team_b })
puts "Game I (id=#{game_i.id})"

# ─── Game J: Doubles, ONGOING, 16 players, host=admin ───
v = venues['Galaxy Badminton Center']
game_j = create_game(
  title: 'Giải đấu 16 người Galaxy', description: '[TEST] 16 người - giải đấu lớn',
  host: admin, match_type: :doubles, max_players: 16, status: :ongoing,
  start_time: now - 20.minutes, end_time: now + 3.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :advanced,
  courts: [3, 4], min_price: 40_000, max_price: 60_000, players_count: 0
)
add_players(game_j, {
  admin => :team_a, u1 => :team_b, u2 => :team_a, u3 => :team_b,
  u4 => :team_a, u5 => :team_b, u6 => :team_a, u7 => :team_b,
  u8 => :team_a, u9 => :team_b, u10 => :team_a, u11 => :team_b,
  u12 => :team_a, u13 => :team_b, u14 => :team_a, u15 => :team_b,
})
if game_j.matches.empty?
  m1 = game_j.matches.create!(match_number: 1, status: :finished,
    team_a_score: 21, team_b_score: 17, winner_team: 'team_a',
    started_at: now - 18.minutes, finished_at: now - 8.minutes)
  m1.match_participations.create!(user: admin, team: :team_a, winner: true)
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
puts "Game J (id=#{game_j.id})"

# ─── Game K: Doubles OPEN, Q.7, host=Trung ───
v = venues['Quận 7 Sports Club']
game_k = create_game(
  title: 'Doubles Q7 chiều nay', description: '[TEST] Doubles open Q7',
  host: u17, match_type: :doubles, max_players: 8, status: :open,
  start_time: now + 2.hours, end_time: now + 4.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :intermediate, max_tier: :advanced,
  courts: [1, 2], min_price: 60_000, max_price: 80_000, players_count: 0
)
add_players(game_k, { u17 => :team_a, u18 => :team_b, u19 => :team_a, u20 => :team_b })
puts "Game K (id=#{game_k.id})"

# ─── Game L: Singles OPEN, Thủ Đức, host=Hoàng ───
v = venues['Thủ Đức Badminton Arena']
game_l = create_game(
  title: 'Singles Thủ Đức', description: '[TEST] Singles open Thủ Đức',
  host: u19, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 6.hours, end_time: now + 7.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :lower_intermediate, max_tier: :upper_intermediate,
  min_price: 40_000, max_price: 40_000, players_count: 0
)
add_players(game_l, { u19 => :team_a })
puts "Game L (id=#{game_l.id})"

# ─── Game M: Doubles OPEN, Gò Vấp, host=Dũng, 6/8 ───
v = venues['Gò Vấp Sport Center']
game_m = create_game(
  title: 'Giao lưu tối Gò Vấp', description: '[TEST] Doubles open Gò Vấp',
  host: u21, match_type: :doubles, max_players: 8, status: :open,
  start_time: now + 3.hours, end_time: now + 5.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :newbie, max_tier: :intermediate,
  courts: [1, 2], min_price: 35_000, max_price: 50_000, players_count: 0
)
add_players(game_m, {
  u21 => :team_a, u22 => :team_b, u26 => :team_a, u28 => :team_b,
  u14 => :team_a, u20 => :team_b
})
puts "Game M (id=#{game_m.id})"

# ─── Game N: Doubles OPEN, Q2, host=Long, miễn phí ───
v = venues['Quận 2 Badminton']
game_n = create_game(
  title: 'Doubles miễn phí Thảo Điền', description: '[TEST] Doubles free Q2',
  host: u23, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 1.day + 2.hours, end_time: now + 1.day + 4.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :advanced,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_n, { u23 => :team_a, u24 => :team_b })
puts "Game N (id=#{game_n.id})"

# ─── Game O: Singles OPEN, Tân Bình, host=Việt (semi-pro) ───
v = venues['Tân Bình Sports Center']
game_o = create_game(
  title: 'Singles trình cao Tân Bình', description: '[TEST] Singles semi-pro Tân Bình',
  host: u25, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 1.day, end_time: now + 1.day + 1.hour,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :advanced, max_tier: :professional,
  min_price: 100_000, max_price: 100_000, players_count: 0
)
add_players(game_o, { u25 => :team_a })
puts "Game O (id=#{game_o.id})"

# ─── Game P: Doubles ONGOING, Q7, host=Nam, 8 players ───
v = venues['Quận 7 Sports Club']
game_p = create_game(
  title: 'Giải nhỏ Q7 tối', description: '[TEST] Doubles ongoing Q7 8 players',
  host: u27, match_type: :doubles, max_players: 8, status: :ongoing,
  start_time: now - 45.minutes, end_time: now + 2.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :lower_intermediate, max_tier: :upper_intermediate,
  courts: [1, 2], min_price: 50_000, max_price: 70_000, players_count: 0
)
add_players(game_p, {
  u27 => :team_a, u28 => :team_b, u10 => :team_a, u12 => :team_b,
  u13 => :team_a, u16 => :team_b, u22 => :team_a, u30 => :team_b,
})
if game_p.matches.empty?
  m1 = game_p.matches.create!(match_number: 1, status: :finished,
    team_a_score: 21, team_b_score: 16, winner_team: 'team_a',
    started_at: now - 40.minutes, finished_at: now - 20.minutes)
  m1.match_participations.create!(user: u27, team: :team_a, winner: true)
  m1.match_participations.create!(user: u10, team: :team_a, winner: true)
  m1.match_participations.create!(user: u28, team: :team_b, winner: false)
  m1.match_participations.create!(user: u12, team: :team_b, winner: false)
end
puts "Game P (id=#{game_p.id})"

# ========== HN Games ==========

# ─── Game Q: Doubles OPEN, Ba Đình, host=Cường ───
v = venues['Hà Nội Badminton Center']
game_q = create_game(
  title: 'Doubles Ba Đình sáng mai', description: '[TEST] Doubles open HN Ba Đình',
  host: u29, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 12.hours, end_time: now + 14.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :intermediate, max_tier: :professional,
  min_price: 70_000, max_price: 100_000, players_count: 0
)
add_players(game_q, { u29 => :team_a, u17 => :team_b })
puts "Game Q (id=#{game_q.id})"

# ─── Game R: Doubles OPEN, Cầu Giấy, host=Thanh ───
v = venues['Cầu Giấy Sports Club']
game_r = create_game(
  title: 'Giao lưu Cầu Giấy', description: '[TEST] Doubles open HN Cầu Giấy',
  host: u18, match_type: :doubles, max_players: 8, status: :open,
  start_time: now + 1.day + 6.hours, end_time: now + 1.day + 8.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :advanced,
  courts: [1, 2], min_price: 45_000, max_price: 60_000, players_count: 0
)
add_players(game_r, { u18 => :team_a, u21 => :team_b, u24 => :team_a })
puts "Game R (id=#{game_r.id})"

# ─── Game S: Singles OPEN, Thanh Xuân, host=Phương ───
v = venues['Thanh Xuân Badminton']
game_s = create_game(
  title: 'Singles Thanh Xuân', description: '[TEST] Singles open HN Thanh Xuân',
  host: u30, match_type: :singles, max_players: 2, status: :open,
  start_time: now + 8.hours, end_time: now + 9.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :newbie, max_tier: :lower_intermediate,
  min_price: 0, max_price: 0, players_count: 0
)
add_players(game_s, { u30 => :team_a })
puts "Game S (id=#{game_s.id})"

# ─── Game T: Doubles ONGOING, Hoàn Kiếm, host=Trung ───
v = venues['Hoàn Kiếm Arena']
game_t = create_game(
  title: 'Doubles đang chơi Hoàn Kiếm', description: '[TEST] Doubles ongoing HN Hoàn Kiếm',
  host: u17, match_type: :doubles, max_players: 4, status: :ongoing,
  start_time: now - 40.minutes, end_time: now + 80.minutes,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :upper_intermediate, max_tier: :semi_pro,
  min_price: 80_000, max_price: 80_000, players_count: 0
)
add_players(game_t, { u17 => :team_a, u25 => :team_b, u23 => :team_a, u29 => :team_b })
if game_t.matches.empty?
  m1 = game_t.matches.create!(match_number: 1, status: :ongoing,
    started_at: now - 10.minutes)
  m1.match_participations.create!(user: u17, team: :team_a)
  m1.match_participations.create!(user: u23, team: :team_a)
  m1.match_participations.create!(user: u25, team: :team_b)
  m1.match_participations.create!(user: u29, team: :team_b)
end
puts "Game T (id=#{game_t.id})"

# ─── Game U: Doubles OPEN, Long Biên, host=Hà ───
v = venues['Long Biên Sports Center']
game_u = create_game(
  title: 'Doubles Long Biên cuối tuần', description: '[TEST] Doubles open HN Long Biên',
  host: u24, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 2.days, end_time: now + 2.days + 2.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :newbie, max_tier: :intermediate,
  min_price: 25_000, max_price: 40_000, players_count: 0
)
add_players(game_u, { u24 => :team_a })
puts "Game U (id=#{game_u.id})"

# ─── Game V: Doubles OPEN, Hà Đông ───
v = venues['Hà Đông Badminton Club']
game_v = create_game(
  title: 'Giao lưu Hà Đông', description: '[TEST] Doubles open HN Hà Đông',
  host: u19, match_type: :doubles, max_players: 8, status: :open,
  start_time: now + 1.day + 3.hours, end_time: now + 1.day + 5.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :beginner_plus, max_tier: :upper_intermediate,
  courts: [1, 2], min_price: 35_000, max_price: 50_000, players_count: 0
)
add_players(game_v, { u19 => :team_a, u20 => :team_b, u26 => :team_a, u28 => :team_b, u22 => :team_a })
puts "Game V (id=#{game_v.id})"

# ─── Game W: Doubles OPEN, Đống Đa ───
v = venues['Đống Đa Badminton']
game_w = create_game(
  title: 'Doubles tối Đống Đa', description: '[TEST] Doubles open HN Đống Đa',
  host: u27, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 7.hours, end_time: now + 9.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :intermediate, max_tier: :advanced,
  min_price: 55_000, max_price: 70_000, players_count: 0
)
add_players(game_w, { u27 => :team_a, u30 => :team_b })
puts "Game W (id=#{game_w.id})"

# ─── Game X: Doubles OPEN, Nam Từ Liêm ───
v = venues['Nam Từ Liêm Sports']
game_x = create_game(
  title: 'Doubles Nam Từ Liêm', description: '[TEST] Doubles open HN Nam Từ Liêm',
  host: u21, match_type: :doubles, max_players: 4, status: :open,
  start_time: now + 1.day + 5.hours, end_time: now + 1.day + 7.hours,
  venue_id: v.id, lat: v.lat, lng: v.lng, location: "#{v.name} - #{v.address}",
  min_tier: :lower_intermediate, max_tier: :semi_pro,
  min_price: 60_000, max_price: 80_000, players_count: 0
)
add_players(game_x, { u21 => :team_a, u15 => :team_b, u11 => :team_a })
puts "Game X (id=#{game_x.id})"

# ========== Extra HCM games for pagination test ==========

extra_hcm_venues = [
  venues['Galaxy Badminton Center'], venues['Victory Sports'],
  venues['Pro Badminton Center'], venues['Saigon Badminton Club'],
  venues['Phú Nhuận Badminton'], venues['Quận 7 Sports Club'],
  venues['Gò Vấp Sport Center'], venues['Quận 2 Badminton'],
  venues['Tân Bình Sports Center'], venues['Thủ Đức Badminton Arena'],
]
extra_hosts = [u9, u10, u11, u12, u13, u14, u15, u16, u23, u25]
extra_titles = [
  'Đánh nhẹ giải trí', 'Luyện cặp đôi mới', 'Tập trung kỹ thuật',
  'Giao hữu ngẫu hứng', 'Warm-up buổi sáng', 'After-work badminton',
  'Đối kháng nhẹ nhàng', 'Tìm bạn chơi mới', 'Luyện smash & drop',
  'Cuối tuần vui vẻ',
]
tiers = %i[newbie beginner_plus lower_intermediate intermediate upper_intermediate advanced]

10.times do |i|
  ev = extra_hcm_venues[i % extra_hcm_venues.size]
  eh = extra_hosts[i % extra_hosts.size]
  mt = i.even? ? :doubles : :singles
  max_p = mt == :doubles ? [4, 8].sample : 2
  min_t = tiers[rand(0..3)]
  max_t = tiers[[tiers.index(min_t) + rand(1..2), tiers.size - 1].min]

  g = create_game(
    title: extra_titles[i], description: "[TEST] Extra HCM ##{i + 1}",
    host: eh, match_type: mt, max_players: max_p, status: :open,
    start_time: now + (i + 1).hours + rand(0..30).minutes,
    end_time: now + (i + 3).hours + rand(0..30).minutes,
    venue_id: ev.id, lat: ev.lat, lng: ev.lng, location: "#{ev.name} - #{ev.address}",
    min_tier: min_t, max_tier: max_t,
    min_price: [0, 30_000, 40_000, 50_000].sample,
    max_price: [0, 50_000, 60_000, 80_000].sample,
    players_count: 0
  )
  add_players(g, { eh => :team_a })
  puts "Extra HCM ##{i + 1} (id=#{g.id})"
end

# ========== Extra HN games for pagination test ==========

extra_hn_venues = [
  venues['Hà Nội Badminton Center'], venues['Cầu Giấy Sports Club'],
  venues['Thanh Xuân Badminton'], venues['Hoàn Kiếm Arena'],
  venues['Long Biên Sports Center'], venues['Hà Đông Badminton Club'],
  venues['Đống Đa Badminton'], venues['Nam Từ Liêm Sports'],
]
extra_hn_titles = [
  'Giao lưu HN sáng', 'Doubles Hà Nội tối', 'Singles nhanh',
  'Tập tành cuối tuần', 'Warm up buổi trưa', 'Đối kháng HN',
  'Tìm đối thủ xứng tầm', 'Doubles nhẹ nhàng HN',
]

8.times do |i|
  ev = extra_hn_venues[i % extra_hn_venues.size]
  eh = extra_hosts[(i + 5) % extra_hosts.size]
  mt = i.even? ? :doubles : :singles
  max_p = mt == :doubles ? [4, 8].sample : 2
  min_t = tiers[rand(0..3)]
  max_t = tiers[[tiers.index(min_t) + rand(1..2), tiers.size - 1].min]

  g = create_game(
    title: extra_hn_titles[i], description: "[TEST] Extra HN ##{i + 1}",
    host: eh, match_type: mt, max_players: max_p, status: :open,
    start_time: now + (i + 2).hours + rand(0..30).minutes,
    end_time: now + (i + 4).hours + rand(0..30).minutes,
    venue_id: ev.id, lat: ev.lat, lng: ev.lng, location: "#{ev.name} - #{ev.address}",
    min_tier: min_t, max_tier: max_t,
    min_price: [0, 30_000, 45_000].sample,
    max_price: [0, 50_000, 65_000, 80_000].sample,
    players_count: 0
  )
  add_players(g, { eh => :team_a })
  puts "Extra HN ##{i + 1} (id=#{g.id})"
end

# ── Sync global ratings (host skill on participations + W/L → displayed tier) ──
Seeds::RatingHelpers.apply_host_skills_from_profiles!(RANK_PROFILES)
Seeds::RatingHelpers.sync_all_global_ratings!
puts "Synced global ratings for #{User.joins(:rank).count} players"

# ── Summary ─────────────────────────────────────────────────────
puts ''
puts '=== Seed Summary ==='
puts "Users:       #{User.count}"
puts "Venues:      #{Venue.count}"
puts "Games:       #{Game.count}"
puts "Matches:     #{Match.count}"
puts ''
puts '=== Test Accounts ==='
puts 'Email: t16021999@gmail.com   Pass: 123123123    (Tân Admin - host Game J 16 người)'
puts 'Email: player1@example.com   Pass: password123   (Tân - host Game A, B, F, I)'
puts 'Email: player2@example.com   Pass: password123   (Minh - host Game C)'
puts ''
puts '=== Rating (seed) ==='
puts 'Declared skill = tier + stars (Rank.rating_from_tier_and_stars)'
puts 'Global rank = avg(host-rated base) + 10×W − 7×L (see Users::GlobalRatingCalculator)'
puts "Example player1: declared #{Rank.rating_from_tier_and_stars(:advanced, 4)} pts (advanced 4★)"
puts ''
puts '=== Games (HCM) ==='
puts "Game A (id=#{game_a.id}): Doubles ONGOING, 4 người, 2 matches"
puts "Game B (id=#{game_b.id}): Singles FULL, 2 người"
puts "Game C (id=#{game_c.id}): Doubles OPEN, 3/4 người"
puts "Game D (id=#{game_d.id}): Doubles ONGOING, Tân ko join"
puts "Game E (id=#{game_e.id}): Singles OPEN, chờ đối thủ"
puts "Game F (id=#{game_f.id}): Doubles FINISHED, 3 matches"
puts "Game G (id=#{game_g.id}): Doubles OPEN, 2/4"
puts "Game H (id=#{game_h.id}): Singles OPEN, 1/2"
puts "Game I (id=#{game_i.id}): Doubles ONGOING, 4/4"
puts "Game J (id=#{game_j.id}): Doubles ONGOING, 16 người, 3 matches"
puts "Game K (id=#{game_k.id}): Doubles OPEN, Q7, 4/8"
puts "Game L (id=#{game_l.id}): Singles OPEN, Thủ Đức"
puts "Game M (id=#{game_m.id}): Doubles OPEN, Gò Vấp, 6/8"
puts "Game N (id=#{game_n.id}): Doubles OPEN, Q2, miễn phí"
puts "Game O (id=#{game_o.id}): Singles OPEN, Tân Bình, trình cao"
puts "Game P (id=#{game_p.id}): Doubles ONGOING, Q7, 8 người"
puts "+ 10 extra HCM games"
puts ''
puts '=== Games (HN) ==='
puts "Game Q (id=#{game_q.id}): Doubles OPEN, Ba Đình"
puts "Game R (id=#{game_r.id}): Doubles OPEN, Cầu Giấy, 3/8"
puts "Game S (id=#{game_s.id}): Singles OPEN, Thanh Xuân"
puts "Game T (id=#{game_t.id}): Doubles ONGOING, Hoàn Kiếm"
puts "Game U (id=#{game_u.id}): Doubles OPEN, Long Biên"
puts "Game V (id=#{game_v.id}): Doubles OPEN, Hà Đông, 5/8"
puts "Game W (id=#{game_w.id}): Doubles OPEN, Đống Đa"
puts "Game X (id=#{game_x.id}): Doubles OPEN, Nam Từ Liêm, 3/4"
puts "+ 8 extra HN games"
puts ''
puts '=== Venues ==='
puts "HCM: #{Venue.where(city: 'HCM').count} venues"
puts "HN:  #{Venue.where(city: 'HN').count} venues"
puts '===================='
