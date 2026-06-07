# frozen_string_literal: true

class GameSettlement < ApplicationRecord
  belongs_to :game
  belongs_to :updated_by, class_name: 'User', optional: true

  enum :mode, { split_evenly: 0, fixed_price: 1 }
  enum :status, { draft: 0, published: 1 }

  GENDER_STEP_VND = 1_000

  validates :expense_lines, presence: true
  validates :gender_adjustment_steps, numericality: { only_integer: true }
  validates :fixed_male_price, :fixed_female_price, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validate :expense_lines_shape

  def expense_lines_array
    Array(expense_lines).map do |line|
      line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
      qty = line[:quantity].presence || line[:shuttle_count]
      unit = line[:unit_vnd].presence || line[:shuttle_unit_vnd]
      kind = line[:kind].to_s
      shuttle = kind == 'shuttle' || line[:label].to_s.match?(/\Acầu/i)
      base = {
        id: line[:id].to_s,
        label: line[:label].to_s,
        quantity: qty.to_i,
        unit_vnd: unit.to_i,
        amount: line[:amount].to_i,
        included: line_included?(line),
        kind: shuttle ? 'shuttle' : 'generic'
      }
      if shuttle
        base.merge(
          shuttle_tube_vnd: (line[:shuttle_tube_vnd].presence || 325_000).to_i,
          shuttle_per_tube: [(line[:shuttle_per_tube].presence || 12).to_i, 1].max
        )
      else
        base
      end
    end
  end

  def shuttle_settings_hash
    shuttle = Array(expense_lines).find do |line|
      line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
      line[:kind].to_s == 'shuttle' || line[:label].to_s.match?(/\Acầu/i)
    end
    return nil if shuttle.blank?

    shuttle = shuttle.deep_symbolize_keys if shuttle.respond_to?(:deep_symbolize_keys)
    {
      name: shuttle[:label].to_s.presence || 'Cầu 88',
      tube_vnd: (shuttle[:shuttle_tube_vnd].presence || 325_000).to_i,
      per_tube: [(shuttle[:shuttle_per_tube].presence || 12).to_i, 1].max
    }
  end

  def total_expense
    expense_lines_array.sum { |l| l[:included] ? l[:amount] : 0 }
  end

  private

  def line_included?(line)
    val = line[:included]
    val = line['included'] if val.nil?
    val != false && val != 'false' && val != 0
  end

  def expense_lines_shape
    return errors.add(:expense_lines, 'must be an array') unless expense_lines.is_a?(Array)

    expense_lines.each_with_index do |line, idx|
      unless line.is_a?(Hash) && line['label'].present? || line[:label].present?
        errors.add(:expense_lines, "line #{idx + 1} missing label")
      end
      amount = line['amount'] || line[:amount]
      unless amount.is_a?(Numeric) && amount.to_i >= 0
        errors.add(:expense_lines, "line #{idx + 1} invalid amount")
      end
    end
  end
end
