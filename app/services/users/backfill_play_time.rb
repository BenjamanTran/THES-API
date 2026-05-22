# frozen_string_literal: true

module Users
  # Idempotent: cộng giờ cho mọi game đã join nhưng chưa credited (kể cả dữ liệu cũ).
  class BackfillPlayTime
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return 0 unless @user.rank
      return 0 unless GameParticipation.exists?(user_id: @user.id, play_time_credited: false)

      pending = uncredited_participations
      return 0 if pending.empty?

      total_seconds = pending.sum { |gp| gp.game.duration_seconds }
      return 0 if total_seconds <= 0

      rank = @user.rank
      ids = pending.map(&:id)

      ActiveRecord::Base.transaction do
        rank.update!(play_time_seconds: rank.play_time_seconds + total_seconds)
        GameParticipation.where(id: ids).update_all(play_time_credited: true)
      end

      total_seconds
    end

    private

    def uncredited_participations
      GameParticipation
        .includes(:game, user: :rank)
        .where(user_id: @user.id, play_time_credited: false)
        .reject { |gp| gp.user.placeholder? }
        .select { |gp| gp.game.duration_seconds.positive? }
    end
  end
end
