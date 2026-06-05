# frozen_string_literal: true

module Games
  class SettlementCalculator
    GENDER_STEP = GameSettlement::GENDER_STEP_VND
    SHARE_ROUND_VND = 500

    PlayerRow = Struct.new(:id, :name, :gender, :amount, keyword_init: true)

    def initialize(game:, settlement:)
      @game = game
      @settlement = settlement
    end

    def call
      arrived = arrived_players
      gendered = arrived.select { |p| %w[male female].include?(p[:gender]) }
      males = gendered.select { |p| p[:gender] == 'male' }
      females = gendered.select { |p| p[:gender] == 'female' }
      ungendered = arrived.reject { |p| %w[male female].include?(p[:gender]) }

      total_expense = @settlement.total_expense

      base = {
        total_expense: total_expense,
        arrived_count: arrived.size,
        male_count: males.size,
        female_count: females.size,
        ungendered_players: ungendered.map { |p| { id: p[:id], name: p[:name] } },
        errors: []
      }

      if @settlement.split_evenly?
        base.merge(split_evenly_result(total_expense, males, females, gendered, arrived, ungendered))
      else
        base.merge(fixed_price_result(total_expense, males, females))
      end
    end

    private

    def arrived_players
      @game.game_participations
           .includes(:user)
           .select(&:arrived_at_court)
           .map do |gp|
        user = gp.user
        {
          id: user.id,
          name: user.name,
          gender: user.gender,
          is_host: @game.host_id == user.id
        }
      end
    end

    def split_evenly_result(total_expense, males, females, gendered, arrived, ungendered)
      return empty_split('Chưa có người đã đến sân') if arrived.empty?
      return empty_split('Tổng chi phải lớn hơn 0') if total_expense <= 0

      steps = @settlement.gender_adjustment_steps
      nm = males.size
      nf = females.size

      pool = gendered.presence || arrived

      male_display_unit = nil
      female_display_unit = nil

      if nm.positive? && nf.positive? && steps != 0
        base_even = total_expense.to_f / (nm + nf)
        male_unit = ceil_share_amount(base_even + steps * GENDER_STEP)

        if male_unit * nm > total_expense
          return empty_split('Điều chỉnh nam quá cao — nữ âm tiền')
        end

        female_unit = nf.positive? ? ceil_share_amount((total_expense - male_unit * nm) / nf.to_f) : 0

        male_display_unit = male_unit
        female_display_unit = female_unit
        per_player = assign_gender_shares(pool, male_unit, female_unit)
      else
        unit = ceil_share_amount(total_expense.to_f / n)
        per_player = pool.map do |p|
          PlayerRow.new(id: p[:id], name: p[:name], gender: p[:gender], amount: unit)
        end
      end

      revenue = per_player.sum(&:amount)

      {
        mode: 'split_evenly',
        revenue: revenue,
        profit: revenue - total_expense,
        male_unit: male_display_unit,
        female_unit: female_display_unit,
        per_player: per_player.map(&:to_h),
        warnings: ungendered.any? ? ['Một số người đến chưa có giới tính — không tính vào chia tiền'] : []
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

    def fixed_price_result(total_expense, males, females)
      nm = males.size
      nf = females.size
      male_price = @settlement.fixed_male_price
      female_price = @settlement.fixed_female_price
      revenue = male_price * nm + female_price * nf
      profit = revenue - total_expense

      warnings = []
      warnings << 'Chưa có người đã đến có giới tính' if nm.zero? && nf.zero?

      {
        mode: 'fixed_price',
        revenue: revenue,
        profit: profit,
        male_unit: male_price,
        female_unit: female_price,
        per_player: nil,
        warnings: warnings
      }
    end

    def empty_split(message)
      {
        mode: 'split_evenly',
        revenue: 0,
        profit: 0,
        male_unit: nil,
        female_unit: nil,
        per_player: [],
        errors: [message],
        warnings: []
      }
    end
  end
end
