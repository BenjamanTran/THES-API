# frozen_string_literal: true

module Games
  class PlaceholderService < ApplicationService
    def initialize(user:, game:, params: {})
      super()
      @user = user
      @game = game
      @params = params
    end

    def create
      return failure('Only host or co-host can add placeholder players', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Cannot add placeholders to a finished or cancelled game') unless editable_status?
      return failure('Name is required') if @params[:name].to_s.strip.blank?

      ActiveRecord::Base.transaction do
        @game.lock!
        return failure('Game is already full') if @game.players_count >= @game.max_players

        placeholder = User.create!(
          name: @params[:name].to_s.strip,
          gender: @params[:gender].presence || :unspecified,
          placeholder: true,
          guest: false
        )

        rank_result = apply_rank!(placeholder, required: true)
        return rank_result if rank_result.is_a?(ServiceResult)

        @game.game_participations.create!(user: placeholder, team: assign_team, role: :player)
        @game.update!(players_count: @game.players_count + 1)
        @game.update!(status: :full) if @game.open? && @game.players_count >= @game.max_players

        success(player: placeholder)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    def update
      placeholder = find_placeholder!
      return placeholder if placeholder.is_a?(ServiceResult)

      placeholder.name = @params[:name].to_s.strip if @params.key?(:name)
      placeholder.gender = @params[:gender] if @params.key?(:gender)

      ActiveRecord::Base.transaction do
        placeholder.save!
        if tier_params_present?
          rank_result = apply_rank!(placeholder)
          return rank_result if rank_result.is_a?(ServiceResult)
        end
      end

      success(player: placeholder.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    def destroy
      placeholder = find_placeholder!
      return placeholder if placeholder.is_a?(ServiceResult)

      gp = @game.game_participations.find_by!(user: placeholder)

      ActiveRecord::Base.transaction do
        gp.destroy!
        @game.update!(players_count: [@game.players_count - 1, 0].max)
        @game.update!(status: :open) if @game.full? && !@game.ongoing? && @game.players_count < @game.max_players
        placeholder.destroy!
      end

      success
    rescue ActiveRecord::RecordNotFound
      failure('Placeholder player not found in this game', :not_found)
    end

    private

    def editable_status?
      !@game.finished? && !@game.cancelled?
    end

    def find_placeholder!
      return failure('Only host or co-host can manage placeholder players', :forbidden) unless @game.host_or_co_host?(@user)
      return failure('Cannot manage placeholders in a finished or cancelled game') unless editable_status?

      placeholder = User.placeholders.find_by(id: @params[:id])
      return failure('Placeholder player not found', :not_found) unless placeholder
      return failure('Player is not in this game') unless @game.game_participations.exists?(user_id: placeholder.id)

      placeholder
    end

    def tier_params_present?
      @params.key?(:tier) || @params.key?(:stars)
    end

    def apply_rank!(user, required: false)
      return unless required || tier_params_present? || user.rank.nil?

      tier_key = normalize_tier(@params[:tier].presence || 'newbie')
      return failure('Invalid tier') unless tier_key

      stars = @params[:stars].presence || 3
      rating = Rank.rating_from_tier_and_stars(tier_key, stars)
      division = tier_key == :professional ? nil : 3

      declared = { declared_tier: Rank.tiers[tier_key], declared_rating: rating }
      if user.rank
        user.rank.update!(tier: tier_key, rating: rating, division: division, **declared)
      else
        user.create_rank!(tier: tier_key, rating: rating, division: division, **declared)
      end

      nil
    end

    def normalize_tier(raw)
      key = raw.to_s.presence
      return key.to_sym if key && Rank.tiers.key?(key)

      nil
    end

    def assign_team
      team_a_count = @game.game_participations.team_a.count
      team_b_count = @game.game_participations.team_b.count
      team_a_count <= team_b_count ? :team_a : :team_b
    end
  end
end
