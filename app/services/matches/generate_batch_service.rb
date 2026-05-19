# frozen_string_literal: true

module Matches
  class GenerateBatchService < ApplicationService
    ALLOWED_COUNTS = [5, 10, 15].freeze

    def initialize(user:, game:, count:)
      @user = user
      @game = game
      @count = count.to_i
    end

    def call
      return failure('Only host or co-host can create matches', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Game is not active') if @game.finished? || @game.cancelled?
      return failure('Invalid batch count') unless ALLOWED_COUNTS.include?(@count)
      return failure('Not enough players for a match') unless enough_players?

      team_size = @game.doubles? ? 2 : 1
      needed = team_size * 2
      scheduled = scheduled_counts
      participant_ids = @game.game_participations.pluck(:user_id)
      users = User.includes(:rank).where(id: participant_ids).index_by(&:id)

      created = []
      ActiveRecord::Base.transaction do
        @count.times do
          roster = pick_roster(participant_ids, scheduled, needed)
          break if roster.length < needed

          team_a, team_b = split_teams(roster, users, team_size)
          next_number = (@game.matches.maximum(:match_number) || 0) + 1

          match = @game.matches.create!(match_number: next_number, status: :pending)
          team_a.each { |uid| match.match_participations.create!(user_id: uid, team: :team_a) }
          team_b.each { |uid| match.match_participations.create!(user_id: uid, team: :team_b) }

          roster.each { |uid| scheduled[uid] = (scheduled[uid] || 0) + 1 }
          match.match_participations.includes(user: :rank).load
          created << match
        end
      end

      return failure('Could not generate any matches') if created.empty?

      success(matches: created)
    end

    private

    def enough_players?
      min = @game.doubles? ? 4 : 2
      @game.players_count >= min
    end

    # All lineups in session (pending + ongoing + finished) — avoid stacking queue slots.
    def scheduled_counts
      counts = Hash.new(0)
      @game.matches.includes(:match_participations).find_each do |match|
        match.match_participations.each { |mp| counts[mp.user_id] += 1 }
      end
      counts
    end

    def pick_roster(participant_ids, scheduled, needed)
      return [] if participant_ids.length < needed

      best = nil
      best_sum = nil

      participant_ids.combination(needed).each do |combo|
        sum = combo.sum { |id| scheduled[id] || 0 }
        if best.nil? || sum < best_sum || (sum == best_sum && combo.sort < best.sort)
          best_sum = sum
          best = combo
        end
      end

      best || []
    end

    def split_teams(roster, users_by_id, team_size)
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
