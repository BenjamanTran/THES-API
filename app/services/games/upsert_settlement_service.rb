# frozen_string_literal: true

module Games
  class UpsertSettlementService < ApplicationService
    def initialize(user:, game:, params:)
      super()
      @user = user
      @game = game
      @params = params
    end

    def call
      unless @game.host_or_co_host?(@user)
        return failure('Only host or co-host can edit settlement', :forbidden)
      end

      settlement = @game.game_settlement || @game.build_game_settlement
      if settlement.published?
        return failure('Published settlement cannot be edited — create a new draft first', :unprocessable_content)
      end

      settlement.assign_attributes(
        mode: @params[:mode],
        expense_lines: normalize_expense_lines(@params[:expense_lines]),
        gender_adjustment_steps: @params[:gender_adjustment_steps].to_i,
        fixed_male_price: @params[:fixed_male_price].to_i,
        fixed_female_price: @params[:fixed_female_price].to_i,
        updated_by: @user,
        status: :draft
      )

      settlement.save!
      computed = SettlementCalculator.new(game: @game.reload, settlement: settlement).call
      success(settlement: settlement, computed: computed)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    end

    private

    def normalize_expense_lines(lines)
      Array(lines).map do |line|
        line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
        line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
        qty = (line[:quantity].presence || line[:shuttle_count]).to_i
        unit = (line[:unit_vnd].presence || line[:shuttle_unit_vnd]).to_i
        amount = qty.positive? && unit.positive? ? qty * unit : line[:amount].to_i
        {
          'id' => (line[:id].presence || SecureRandom.uuid),
          'label' => line[:label].to_s.strip,
          'quantity' => qty,
          'unit_vnd' => unit,
          'amount' => amount
        }
      end.reject { |l| l['label'].blank? && l['amount'].zero? }
    end
  end
end
