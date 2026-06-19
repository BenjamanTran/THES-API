# frozen_string_literal: true

module Users
  class SkillProfilePayload
    AXIS_LABELS = {
      attack: 'Tấn công',
      defense: 'Phòng thủ',
      technique: 'Kỹ thuật',
      agility: 'Nhanh nhẹn',
      footwork: 'Bộ pháp',
      stamina: 'Thể lực'
    }.freeze

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      snapshots = @user.skill_snapshots.order(month: :desc).limit(12).to_a
      current = snapshots.first

      {
        skill_radar: current && snapshot_payload(current),
        skill_history: snapshots.map { |snapshot| snapshot_payload(snapshot) }
      }
    end

    private

    def snapshot_payload(snapshot)
      {
        month: snapshot.month.iso8601,
        overall_score: snapshot.overall_score.to_f,
        declared_tier: snapshot.declared_tier_key,
        computed_stars: UserSkillSnapshot.computed_stars_from_overall(snapshot.overall_score),
        declared_rating: snapshot.declared_rating,
        axes: UserSkillSnapshot::AXES.map do |axis|
          {
            key: axis.to_s,
            label: AXIS_LABELS.fetch(axis),
            score: snapshot.public_send(axis)
          }
        end
      }
    end
  end
end
