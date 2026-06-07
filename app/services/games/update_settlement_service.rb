# frozen_string_literal: true

module Games
  class UpdateSettlementService < ApplicationService
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
      was_published = settlement.published?

      settlement.assign_attributes(
        mode: @params[:mode],
        expense_lines: normalize_expense_lines(@params[:expense_lines]),
        gender_adjustment_steps: @params[:gender_adjustment_steps].to_i,
        fixed_male_price: @params[:fixed_male_price].to_i,
        fixed_female_price: @params[:fixed_female_price].to_i,
        updated_by: @user
      )
      settlement.status = :draft if settlement.new_record?

      game = @game
      computed = SettlementCalculator.new(game: game, settlement: settlement).call
      if computed[:errors]&.any?
        return failure(computed[:errors].join(', '), :unprocessable_content)
      end

      settlement.save!
      game = @game.reload
      computed = SettlementCalculator.new(game: game, settlement: settlement).call

      broadcast_if_published(game) if was_published || settlement.published?

      success(settlement: settlement, computed: computed)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    end

    private

    def broadcast_if_published(game)
      Games::CableBroadcaster.broadcast(game: game, event: 'game.refresh')
    end

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
          'amount' => amount,
          'included' => line[:included].nil? ? true : ActiveModel::Type::Boolean.new.cast(line[:included])
        }
      end.reject { |l| l['label'].blank? && l['amount'].zero? }
    end
  end
end
