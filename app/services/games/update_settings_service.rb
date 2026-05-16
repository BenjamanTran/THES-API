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
      return failure('Cannot edit while the game is ongoing') if @game.ongoing?

      attrs = build_attrs
      return attrs if attrs.is_a?(ServiceResult)

      return failure('No changes provided') if attrs.empty?

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
