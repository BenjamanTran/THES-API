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
        sections: normalize_sections(@params[:sections]),
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

    def normalize_sections(raw_sections)
      Array(raw_sections).map do |sec|
        sec = sec.to_unsafe_h if sec.respond_to?(:to_unsafe_h)
        sec = sec.deep_symbolize_keys if sec.respond_to?(:deep_symbolize_keys)
        mode = %w[split_evenly fixed_price].include?(sec[:mode].to_s) ? sec[:mode].to_s : 'split_evenly'
        {
          'id' => sec[:id].to_s.presence || SecureRandom.uuid,
          'label' => sec[:label].to_s.strip.presence || 'Phần 1',
          'mode' => mode,
          'expense_lines' => normalize_expense_lines(sec[:expense_lines]),
          'desired_female_price' => sec[:desired_female_price].to_i,
          'fixed_male_price' => sec[:fixed_male_price].to_i,
          'fixed_female_price' => sec[:fixed_female_price].to_i,
          'participant_ids' => Array(sec[:participant_ids]).map(&:to_i).uniq
        }
      end
    end

    def normalize_expense_lines(lines)
      Array(lines).map do |line|
        line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
        line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
        qty = (line[:quantity].presence || line[:shuttle_count]).to_i
        kind = line[:kind].to_s
        shuttle = kind == 'shuttle' || line[:label].to_s.match?(/\Acầu/i)

        if shuttle
          tube = (line[:shuttle_tube_vnd].presence || 325_000).to_i
          per = [(line[:shuttle_per_tube].presence || 12).to_i, 1].max
          amount = per.positive? ? ((qty * tube) / per.to_f).round : 0
          unit = per.positive? ? (tube.to_f / per).round : 0
          {
            'id' => line[:id].presence || SecureRandom.uuid,
            'label' => line[:label].to_s.strip.presence || 'Cầu 88',
            'kind' => 'shuttle',
            'quantity' => qty,
            'shuttle_tube_vnd' => tube,
            'shuttle_per_tube' => per,
            'unit_vnd' => unit,
            'amount' => amount,
            'included' => line[:included].nil? || ActiveModel::Type::Boolean.new.cast(line[:included])
          }
        else
          unit = (line[:unit_vnd].presence || line[:shuttle_unit_vnd]).to_i
          amount = qty.positive? && unit.positive? ? qty * unit : line[:amount].to_i
          {
            'id' => line[:id].presence || SecureRandom.uuid,
            'label' => line[:label].to_s.strip,
            'kind' => 'generic',
            'quantity' => qty,
            'unit_vnd' => unit,
            'amount' => amount,
            'included' => line[:included].nil? || ActiveModel::Type::Boolean.new.cast(line[:included])
          }
        end
      end.reject { |l| l['label'].blank? && l['amount'].zero? }
    end

    def normalize_shuttle_settings(raw)
      return if raw.blank?

      raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
      raw = raw.deep_symbolize_keys if raw.respond_to?(:deep_symbolize_keys)
      {
        'name' => raw[:name].to_s.strip.presence || 'Cầu 88',
        'tube_vnd' => raw[:tube_vnd].to_i,
        'per_tube' => [raw[:per_tube].to_i, 1].max
      }
    end
  end
end
