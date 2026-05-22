# frozen_string_literal: true

module Games
  class GameService < ApplicationService
    def initialize(user:, game: nil, params: nil)
      super()
      @user = user
      @game = game
      @params = params
    end

    def create
      game = Game.new(@params)
      game.host = @user
      game.status = :open
      game.players_count = 1

      if game.venue_id.present? && (venue = Venue.find_by(id: game.venue_id))
        game.lat ||= venue.lat
        game.lng ||= venue.lng
        game.location ||= [venue.name, venue.address].compact_blank.join(' - ')
      end

      ActiveRecord::Base.transaction do
        game.save!
        game.game_participations.create!(user: @user, team: :team_a)
        Users::CreditPlayTimeForJoin.call(game: game, user: @user)
      end

      Users::ProfileCache.bust_for_user!(@user.id)
      success(game: game)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    def join
      return failure('Game is not open for joining') unless @game.open?
      return failure('You have already joined this game') if already_joined?
      return failure('You have a time conflict with another game', :conflict) if time_conflict?

      warning = 'This match may not fit your level' if tier_mismatch?
      add_player(warning)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    def leave
      participation = @game.game_participations.find_by(user: @user)
      return failure('You are not in this game') unless participation
      return failure('Cannot leave an ongoing game') if @game.ongoing?

      @user.id == @game.host_id ? cancel_game : remove_player(participation)
      success
    end

    private

    def add_player(warning)
      team = assign_team

      ActiveRecord::Base.transaction do
        @game.lock!
        return failure('Game is already full') if @game.players_count >= @game.max_players

        @game.game_participations.create!(user: @user, team: team)
        @game.update!(players_count: @game.players_count + 1)
        @game.update!(status: :full) if @game.players_count >= @game.max_players
        Users::CreditPlayTimeForJoin.call(game: @game, user: @user)
      end

      Users::ProfileCache.bust_for_user!(@user.id)
      success(warning: warning)
    end

    def cancel_game
      ActiveRecord::Base.transaction do
        @game.game_participations.find_each do |gp|
          Users::RevertPlayTimeOnLeave.call(game: @game, participation: gp)
        end
        @game.update!(status: :cancelled)
        @game.game_participations.destroy_all
        @game.update!(players_count: 0)
      end
    end

    def remove_player(participation)
      ActiveRecord::Base.transaction do
        Users::RevertPlayTimeOnLeave.call(game: @game, participation: participation)
        participation.destroy!
        @game.update!(players_count: @game.players_count - 1)
        @game.update!(status: :open) if @game.full?
      end
    end

    def already_joined?
      @game.game_participations.exists?(user: @user)
    end

    def time_conflict?
      @user.games
           .where.not(id: @game.id)
           .where.not(status: :cancelled)
           .exists?(['start_time < ? AND end_time > ?', @game.end_time, @game.start_time])
    end

    def tier_mismatch?
      rank = @user.rank
      return false unless rank

      tiers = Game::TIERS
      user_tier_val = tiers[rank.tier] || 0
      min_val = tiers[@game.min_tier] || 0
      max_val = tiers[@game.max_tier] || 0

      user_tier_val < min_val || user_tier_val > max_val
    end

    def assign_team
      team_a_count = @game.game_participations.team_a.count
      team_b_count = @game.game_participations.team_b.count
      team_a_count <= team_b_count ? :team_a : :team_b
    end
  end
end
