# frozen_string_literal: true

class UserSkill < ApplicationRecord
  belongs_to :user

  validates :skill_code, presence: true, inclusion: { in: Skill::CODES }
  validates :level, presence: true, inclusion: { in: 1..10 }
  validates :user_id, uniqueness: { scope: :skill_code }

  def skill
    Skill.find(skill_code)
  end
end
