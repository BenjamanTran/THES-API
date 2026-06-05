# frozen_string_literal: true

module Api
  module V1
    class SettlementsController < BaseController
      before_action :set_game
      before_action :require_participant!, only: %i[show]
      before_action :require_manager!, only: %i[update publish]

      def show
        settlement = @game.game_settlement
        if settlement.nil?
          return render json: settlement_payload(nil, computed: nil, editable: manager?)
        end

        unless manager? || settlement.published?
          return render json: settlement_payload(nil, computed: nil, editable: false, message: 'Host chưa công bố')
        end

        computed = Games::SettlementCalculator.new(game: @game, settlement: settlement).call
        render json: settlement_payload(settlement, computed: computed, editable: manager? && settlement.draft?)
      end

      def update
        result = Games::UpsertSettlementService.call(
          user: @current_user,
          game: @game,
          params: settlement_params
        )
        if result.success?
          render json: settlement_payload(
            result.data[:settlement],
            computed: result.data[:computed],
            editable: true
          )
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def publish
        result = Games::PublishSettlementService.call(user: @current_user, game: @game)
        if result.success?
          render json: settlement_payload(
            result.data[:settlement],
            computed: result.data[:computed],
            editable: false
          )
        else
          render json: { error: result.error }, status: result.status
        end
      end

      private

      def set_game
        @game = Game.includes(game_participations: :user).find(params[:game_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def require_participant!
        return if @game.participant?(@current_user)

        render json: { error: 'Forbidden' }, status: :forbidden
      end

      def require_manager!
        return if @game.host_or_co_host?(@current_user)

        render json: { error: 'Only host or co-host can manage settlement' }, status: :forbidden
      end

      def manager?
        @game.host_or_co_host?(@current_user)
      end

      def settlement_params
        params.permit(
          :mode,
          :gender_adjustment_steps,
          :fixed_male_price,
          :fixed_female_price,
          expense_lines: %i[id label amount quantity unit_vnd shuttle_count shuttle_unit_vnd]
        ).to_h.symbolize_keys
      end

      def settlement_payload(settlement, computed:, editable:, message: nil)
        body = {
          editable: editable,
          can_manage: manager?
        }
        body[:message] = message if message

        if settlement
          body[:status] = settlement.status
          body[:settlement] = {
            mode: settlement.mode,
            status: settlement.status,
            expense_lines: settlement.expense_lines_array,
            gender_adjustment_steps: settlement.gender_adjustment_steps,
            fixed_male_price: settlement.fixed_male_price,
            fixed_female_price: settlement.fixed_female_price,
            published_at: settlement.published_at&.iso8601,
            updated_at: settlement.updated_at.iso8601
          }
          body[:computed] = computed if computed
        else
          body[:status] = 'none'
          body[:settlement] = nil
          body[:computed] = nil
        end

        body
      end
    end
  end
end
