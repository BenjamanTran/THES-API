# frozen_string_literal: true

module Games
  class SettlementCalculator
    SHARE_ROUND_VND = 500

    PlayerRow = Struct.new(:id, :name, :gender, :amount, keyword_init: true)

    def initialize(game:, settlement:)
      @game = game
      @settlement = settlement
    end

    def call
      all_players = settlement_players
      sections = @settlement.sections_array
      section_results = sections.map { |sec| compute_section(sec, all_players) }

      per_user = aggregate_per_user(section_results)
      total_expense = section_results.sum { |r| r[:total_expense] }
      revenue = section_results.sum { |r| r[:revenue] }
      errors = section_results.flat_map { |r| r[:errors] }
      warnings = section_results.flat_map { |r| r[:warnings] }.uniq

      {
        total_expense: total_expense,
        revenue: revenue,
        profit: revenue - total_expense,
        arrived_count: all_players.count { |p| p[:arrived_at_court] },
        sections: section_results,
        per_player: per_user.values,
        errors: errors,
        warnings: warnings
      }
    end

    private

    def settlement_players
      @game.game_participations.includes(:user).map do |gp|
        user = gp.user
        {
          id: user.id,
          name: user.name,
          gender: user.gender,
          arrived_at_court: gp.arrived_at_court,
          is_host: @game.host_id == user.id
        }
      end
    end

    def compute_section(section, all_players)
      pool = section_pool(section, all_players)
      gendered = pool.select { |p| %w[male female].include?(p[:gender]) }
      males = gendered.select { |p| p[:gender] == 'male' }
      females = gendered.select { |p| p[:gender] == 'female' }
      total_expense = section_total_expense(section[:expense_lines])

      base = section_base(section, total_expense, pool, gendered, males, females)

      if section[:mode] == 'split_evenly'
        base.merge(split_evenly_section(section, total_expense, males, females, gendered, pool))
      else
        base.merge(fixed_price_section(section, total_expense, males, females, pool))
      end
    end

    def section_pool(section, all_players)
      ids = section[:participant_ids].to_set
      all_players.select { |p| ids.include?(p[:id]) }
    end

    def section_total_expense(expense_lines)
      Array(expense_lines).sum do |line|
        line = line.deep_symbolize_keys if line.respond_to?(:deep_symbolize_keys)
        included = line[:included] != false && line[:included] != 'false'
        included ? line[:amount].to_i : 0
      end
    end

    def section_base(section, total_expense, pool, _gendered, males, females)
      ungendered = pool.reject { |p| %w[male female].include?(p[:gender]) }
      {
        id: section[:id],
        label: section[:label],
        mode: section[:mode],
        total_expense: total_expense,
        participant_count: pool.size,
        male_count: males.size,
        female_count: females.size,
        ungendered_players: ungendered.map { |p| { id: p[:id], name: p[:name] } },
        errors: []
      }
    end

    def split_evenly_section(section, total_expense, males, females, gendered, pool)
      return empty_section('split_evenly', total_expense) if pool.empty?
      return empty_section('split_evenly', total_expense, ['Tổng chi phải lớn hơn 0']) if total_expense <= 0

      nm = males.size
      nf = females.size
      compute_pool = gendered.presence || pool
      desired_female = section[:desired_female_price].to_i

      if nm.positive? && nf.positive? && desired_female.positive?
        female_unit = ceil_share_amount(desired_female)
        remaining = total_expense - (female_unit * nf)
        male_unit = remaining.positive? ? ceil_share_amount(remaining.to_f / nm) : 0
        per_player = assign_gender_shares(compute_pool, male_unit, female_unit)
        build_split_result(per_player, male_unit, female_unit, gendered, pool)
      else
        unit = ceil_share_amount(total_expense.to_f / compute_pool.size)
        per_player =
          compute_pool.map do |p|
            PlayerRow.new(id: p[:id], name: p[:name], gender: p[:gender], amount: unit)
          end
        build_split_result(per_player, unit, unit, gendered, pool)
      end
    end

    def build_split_result(per_player, male_unit, female_unit, gendered, pool)
      revenue = per_player.sum(&:amount)
      warnings = []
      ungendered = pool.reject { |p| %w[male female].include?(p[:gender]) }
      warnings << 'Một số người chưa có giới tính — không tính vào chia tiền' if ungendered.any? && gendered.any?

      {
        revenue: revenue,
        male_unit: male_unit,
        female_unit: female_unit,
        per_player: per_player.map(&:to_h),
        warnings: warnings
      }
    end

    def fixed_price_section(section, _total_expense, males, females, pool)
      nm = males.size
      nf = females.size
      male_price = section[:fixed_male_price].to_i
      female_price = section[:fixed_female_price].to_i
      per_player =
        pool.map do |p|
          amount =
            if p[:gender] == 'male'
              male_price
            else
              (p[:gender] == 'female' ? female_price : 0)
            end
          PlayerRow.new(id: p[:id], name: p[:name], gender: p[:gender], amount: amount)
        end
      revenue = (male_price * nm) + (female_price * nf)

      warnings = []
      warnings << 'Chưa có người có giới tính' if nm.zero? && nf.zero?

      {
        revenue: revenue,
        male_unit: male_price,
        female_unit: female_price,
        per_player: per_player.map(&:to_h),
        warnings: warnings
      }
    end

    def aggregate_per_user(section_results)
      acc = {}
      section_results.each do |result|
        Array(result[:per_player]).each do |row|
          entry = acc[row[:id]] ||= { id: row[:id], name: row[:name], gender: row[:gender], amount: 0, sections: [] }
          entry[:name] = row[:name] if row[:name]
          entry[:gender] ||= row[:gender]
          entry[:amount] += row[:amount].to_i
          entry[:sections] << { section_id: result[:id], label: result[:label], amount: row[:amount].to_i }
        end
      end
      acc
    end

    def empty_section(_mode, _total_expense, errors = [])
      {
        revenue: 0,
        male_unit: nil,
        female_unit: nil,
        per_player: [],
        warnings: [],
        errors: errors
      }
    end

    def ceil_share_amount(raw)
      return 0 if raw <= 0

      (raw.to_f / SHARE_ROUND_VND).ceil * SHARE_ROUND_VND
    end

    def assign_gender_shares(pool, male_unit, female_unit)
      pool.map do |p|
        amount = p[:gender] == 'male' ? male_unit : female_unit
        PlayerRow.new(id: p[:id], name: p[:name], gender: p[:gender], amount: amount)
      end
    end
  end
end
