# frozen_string_literal: true

module Games
  module PlayerPairConstraint
    module_function

    def split_pairs_in_lineup?(game, team_a_ids, team_b_ids)
      active_pairs(game).any? do |pair|
        pair_split?(team_a_ids, team_b_ids, pair.user_a_id, pair.user_b_id)
      end
    end

    def pair_split?(team_a_ids, team_b_ids, user_a_id, user_b_id)
      a_on_a = team_a_ids.include?(user_a_id)
      a_on_b = team_b_ids.include?(user_a_id)
      b_on_a = team_a_ids.include?(user_b_id)
      b_on_b = team_b_ids.include?(user_b_id)

      return false unless (a_on_a || a_on_b) && (b_on_a || b_on_b)

      (a_on_a && b_on_b) || (a_on_b && b_on_a)
    end

    def active_pairs(game)
      game.active_player_pairs.to_a
    end

    def validate_lineup!(game, team_a_ids, team_b_ids)
      return nil unless game.doubles?
      return nil if active_pairs(game).empty?
      return nil unless split_pairs_in_lineup?(game, team_a_ids, team_b_ids)

      'Các cặp đánh chung phải cùng một phe'
    end

    def pairs_in_lineup(game, team_a_ids, team_b_ids)
      all_ids = team_a_ids + team_b_ids
      active_pairs(game).select do |pair|
        all_ids.include?(pair.user_a_id) && all_ids.include?(pair.user_b_id)
      end
    end

    def validate_pair_quota!(game, team_a_ids, team_b_ids)
      return nil if game.pair_matches_limit.nil?

      pairs_in_lineup(game, team_a_ids, team_b_ids).each do |pair|
        next unless pair.at_pair_match_limit?(game)

        return "Cặp đã đủ #{game.pair_matches_limit} trận giữ cặp"
      end
      nil
    end

    def increment_pair_usage!(pairs)
      pairs.each { |p| p.increment!(:matches_used) }
    end

    def destroy_pairs_for_user!(game, user_id)
      game.game_player_pairs.active_pairs.where(
        'user_a_id = :uid OR user_b_id = :uid', uid: user_id
      ).find_each(&:destroy!)
    end
  end
end
