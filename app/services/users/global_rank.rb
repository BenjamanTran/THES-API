# frozen_string_literal: true

module Users
  class GlobalRank
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      rank = @user.rank
      return unless rank

      better = Rank.joins(:user)
                   .merge(User.real_accounts)
                   .where('ranks.rating > ?', rank.rating)
                   .count

      better + 1
    end
  end
end
