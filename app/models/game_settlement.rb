# frozen_string_literal: true

class GameSettlement < ApplicationRecord
  belongs_to :game
  belongs_to :updated_by, class_name: 'User', optional: true

  enum :status, { draft: 0, published: 1 }

  validate :sections_shape

  def sections_array
    Array(sections).map { |sec| normalize_section(sec) }
  end

  private

  def normalize_section(raw)
    raw = raw.deep_symbolize_keys if raw.respond_to?(:deep_symbolize_keys)
    {
      id: raw[:id].to_s.presence || SecureRandom.uuid,
      label: raw[:label].to_s,
      mode: %w[split_evenly fixed_price].include?(raw[:mode].to_s) ? raw[:mode].to_s : 'split_evenly',
      expense_lines: normalize_expense_lines(raw[:expense_lines]),
      desired_female_price: raw[:desired_female_price].to_i,
      fixed_male_price: raw[:fixed_male_price].to_i,
      fixed_female_price: raw[:fixed_female_price].to_i,
      participant_ids: Array(raw[:participant_ids]).map(&:to_i)
    }
  end

  def normalize_expense_lines(raw_lines)
    Array(raw_lines).map do |line|
      line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
      qty = (line[:quantity].presence || line[:shuttle_count]).to_i
      unit = (line[:unit_vnd].presence || line[:shuttle_unit_vnd]).to_i
      kind = line[:kind].to_s
      shuttle = kind == 'shuttle' || line[:label].to_s.match?(/\Acầu/i)
      base = {
        id: line[:id].to_s,
        label: line[:label].to_s,
        quantity: qty,
        unit_vnd: unit,
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

  def line_included?(line)
    val = line[:included]
    val = line['included'] if val.nil?
    val != false && val != 'false' && val != 0
  end

  def sections_shape
    return if sections.nil?
    return errors.add(:sections, 'must be an array') unless sections.is_a?(Array)

    sections.each_with_index do |sec, idx|
      sec = sec.deep_symbolize_keys if sec.respond_to?(:deep_symbolize_keys)
      lines = Array(sec[:expense_lines])
      lines.each do |line|
        line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
        amount = line[:amount]
        unless amount.is_a?(Numeric) && amount.to_i >= 0
          errors.add(:sections, "section #{idx + 1} has invalid expense amount")
        end
      end
    end
  end
end
