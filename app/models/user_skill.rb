class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  validates :level, presence: true, inclusion: { in: 1..10 }
  validates :user_id, uniqueness: { scope: :skill_id }
end
