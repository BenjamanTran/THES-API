# frozen_string_literal: true

class AddTechniqueToUserSkillSnapshots < ActiveRecord::Migration[8.1]
  def up
    add_column :user_skill_snapshots, :technique, :integer,
               comment: 'Self-assessed technique score from 1 to 10'

    execute <<~SQL.squish
      UPDATE user_skill_snapshots
      SET technique = GREATEST(
        1,
        LEAST(10, ROUND((attack + defense + agility + footwork + stamina) / 5.0))
      )
    SQL

    recalculate_snapshot_scores!(axis_count: 6, include_technique: true)
    sync_latest_declared_ratings!

    change_column_default :user_skill_snapshots, :technique, from: nil, to: 5
    change_column_null :user_skill_snapshots, :technique, false
  end

  def down
    recalculate_snapshot_scores!(axis_count: 5, include_technique: false)
    sync_latest_declared_ratings!
    remove_column :user_skill_snapshots, :technique
  end

  private

  def recalculate_snapshot_scores!(axis_count:, include_technique:)
    axes = %w[attack defense agility footwork stamina]
    axes << 'technique' if include_technique
    sum = axes.join(' + ')

    execute <<~SQL.squish
      UPDATE user_skill_snapshots
      SET overall_score = ROUND((#{sum}) / #{axis_count}.0, 1)
    SQL

    execute <<~SQL.squish
      UPDATE user_skill_snapshots
      SET computed_stars = GREATEST(0.5, LEAST(5, ROUND(overall_score / 2.0, 2)))
    SQL

    execute <<~SQL.squish
      UPDATE user_skill_snapshots
      SET declared_rating = (declared_tier * 500) + ROUND((computed_stars - 1) * 100)
    SQL
  end

  def sync_latest_declared_ratings!
    execute <<~SQL.squish
      UPDATE ranks
      INNER JOIN user_skill_snapshots current_snapshot
        ON current_snapshot.user_id = ranks.user_id
      LEFT JOIN user_skill_snapshots newer_snapshot
        ON newer_snapshot.user_id = current_snapshot.user_id
       AND newer_snapshot.month > current_snapshot.month
      SET ranks.declared_rating = current_snapshot.declared_rating
      WHERE newer_snapshot.id IS NULL
    SQL
  end
end
