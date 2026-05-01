class Skill < ApplicationRecord
  CODES = %w[smash clear drop drive net_shot lift push block kill].freeze

  has_many :user_skills, dependent: :destroy
  has_many :users, through: :user_skills

  validates :code, presence: true, uniqueness: true, inclusion: { in: CODES }

  def name
    I18n.t("skills.#{code}")
  end
end
