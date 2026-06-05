# frozen_string_literal: true

module Games
  class PublishSettlementService < ApplicationService
    def initialize(user:, game:)
      super()
      @user = user
      @game = game
    end

    def call
      unless @game.host_or_co_host?(@user)
        return failure('Only host or co-host can publish settlement', :forbidden)
      end

      settlement = @game.game_settlement
      return failure('No settlement to publish', :not_found) unless settlement

      computed = SettlementCalculator.new(game: @game, settlement: settlement).call
      if computed[:errors]&.any?
        return failure(computed[:errors].join(', '), :unprocessable_content)
      end

      settlement.update!(
        status: :published,
        published_at: Time.current,
        updated_by: @user
      )

      Games::CableBroadcaster.broadcast(game: @game.reload, event: 'game.refresh')
      success(settlement: settlement, computed: computed)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    end
  end
end
