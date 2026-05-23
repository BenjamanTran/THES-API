# frozen_string_literal: true

module Matches
  class PairAwareLineup
    def initialize(game)
      @game = game
      @partner = partner_map
    end

    def pick_roster(participant_ids, scheduled, needed)
      return [] if participant_ids.length < needed

      best = nil
      best_score = nil

      participant_ids.combination(needed).each do |combo|
        sum = combo.sum { |id| scheduled[id] || 0 }
        split_penalty = roster_split_pair_count(combo) * 10_000
        score = [sum + split_penalty, combo.sort]
        if best.nil? || score < best_score
          best_score = score
          best = combo
        end
      end

      best || []
    end

    def split_teams(roster, users_by_id, team_size)
      return default_split(roster, users_by_id, team_size) if team_size != 2 || @partner.empty?

      groups = pair_groups_in(roster)
      if groups.size >= 2
        g1, g2 = groups.first(2)
        return order_groups_by_rating(g1, g2, users_by_id)
      end

      if groups.size == 1 && roster.length == 4
        pair = groups.first
        singles = roster - pair
        return assign_pair_vs_singles(pair, singles, users_by_id)
      end

      best_split_without_splitting_pairs(roster, users_by_id, team_size) ||
        default_split(roster, users_by_id, team_size)
    end

    private

    def partner_map
      map = {}
      Games::PlayerPairConstraint.active_pairs(@game).each do |pair|
        map[pair.user_a_id] = pair.user_b_id
        map[pair.user_b_id] = pair.user_a_id
      end
      map
    end

    def roster_split_pair_count(roster)
      seen = {}
      splits = 0
      roster.each do |id|
        partner = @partner[id]
        next unless partner

        next if seen[id] || seen[partner]

        seen[id] = true
        seen[partner] = true
        splits += 1 unless roster.include?(partner)
      end
      splits
    end

    def pair_groups_in(roster)
      remaining = roster.dup
      groups = []
      while remaining.any?
        id = remaining.shift
        partner = @partner[id]
        if partner && remaining.include?(partner)
          remaining.delete(partner)
          groups << [id, partner]
        else
          groups << [id]
        end
      end
      groups
    end

    def order_groups_by_rating(group_a, group_b, users_by_id)
      sum_a = group_a.sum { |id| player_rating(users_by_id[id]) }
      sum_b = group_b.sum { |id| player_rating(users_by_id[id]) }
      if sum_a <= sum_b
        [group_a, group_b]
      else
        [group_b, group_a]
      end
    end

    def assign_pair_vs_singles(pair, singles, users_by_id)
      s1, s2 = singles
      pair_sum = pair.sum { |id| player_rating(users_by_id[id]) }
      solo_a = player_rating(users_by_id[s1])
      solo_b = player_rating(users_by_id[s2])

      if (pair_sum + solo_a - solo_b).abs <= (pair_sum + solo_b - solo_a).abs
        [pair, [s1, s2]]
      else
        [pair, [s2, s1]]
      end
    end

    def best_split_without_splitting_pairs(roster, users_by_id, team_size)
      best = nil
      best_diff = nil

      roster.combination(team_size).each do |team_a|
        team_b = roster - team_a
        next if team_b.length != team_size
        next if Games::PlayerPairConstraint.split_pairs_in_lineup?(@game, team_a, team_b)

        diff = (team_a.sum { |id| player_rating(users_by_id[id]) } -
                team_b.sum { |id| player_rating(users_by_id[id]) }).abs
        if best.nil? || diff < best_diff
          best_diff = diff
          best = [team_a, team_b]
        end
      end

      best
    end

    def default_split(roster, users_by_id, team_size)
      rated = roster.sort_by { |id| -player_rating(users_by_id[id]) }
      team_a = rated.each_with_index.filter_map { |id, i| id if i.even? }.first(team_size)
      team_b = rated.each_with_index.filter_map { |id, i| id if i.odd? }.first(team_size)
      [team_a, team_b]
    end

    def player_rating(user)
      return 200 unless user

      user.rank&.rating || 200
    end
  end
end
