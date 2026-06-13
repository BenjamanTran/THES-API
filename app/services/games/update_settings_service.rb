# frozen_string_literal: true

module Games
  class UpdateSettingsService < ApplicationService
    MAX_COURT_NUMBER = 24

    def initialize(user:, game:, params:)
      super()
      @user = user
      @game = game
      @params = params
    end

    def call
      return failure('Only host or co-host can update this game', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Cannot edit a finished or cancelled game') if @game.finished? || @game.cancelled?

      attrs = build_attrs
      return attrs if attrs.is_a?(ServiceResult)

      return failure('No changes provided') if attrs.empty?

      if @game.ongoing? && (attrs.keys - [:pair_matches_limit]).any?
        return failure('Cannot edit while the game is ongoing')
      end

      ActiveRecord::Base.transaction do
        @game.update!(attrs)
        reconcile_status!
      end

      success(game: @game.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def build_attrs
      attrs = {}

      attrs[:start_time] = @params[:start_time] if @params.key?(:start_time)
      attrs[:end_time] = @params[:end_time] if @params.key?(:end_time)

      if @params.key?(:max_players)
        value = @params[:max_players].to_i
        return failure('max_players must be at least 2') if value < 2
        if value < @game.players_count
          return failure("max_players cannot be less than current players (#{@game.players_count})")
        end

        attrs[:max_players] = value
      end

      if @params.key?(:courts)
        courts = Array(@params[:courts]).map(&:to_i).uniq.sort
        return failure('Select at least one court') if courts.empty?
        return failure('Invalid court numbers') if courts.any? { |n| n < 1 || n > MAX_COURT_NUMBER }

        attrs[:courts] = courts
      end

      if @params.key?(:pair_matches_limit)
        return failure('pair_matches_limit is only for doubles games') unless @game.doubles?

        raw = @params[:pair_matches_limit]
        if raw.nil? || raw == '' || raw.to_s == 'unlimited'
          attrs[:pair_matches_limit] = nil
        else
          limit = raw.to_i
          return failure('pair_matches_limit must be at least 1') if limit < 1
          return failure('pair_matches_limit cannot exceed 99') if limit > 99

          attrs[:pair_matches_limit] = limit
        end
      end

      attrs
    end

    def reconcile_status!
      if @game.full? && @game.players_count < @game.max_players
        @game.update!(status: :open)
      elsif @game.open? && @game.players_count >= @game.max_players
        @game.update!(status: :full)
      end
    end
  end
end
