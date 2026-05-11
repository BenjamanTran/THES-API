# frozen_string_literal: true

class User < ApplicationRecord
  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP
  PHONE_REGEX = /\A\+?[0-9\s\-().]{6,20}\z/

  enum :gender, { unspecified: 0, male: 1, female: 2, other: 3 }

  has_secure_password validations: false

  has_many :game_participations, dependent: :destroy
  has_many :games, through: :game_participations
  has_one :rank, dependent: :destroy
  has_many :user_skills, dependent: :destroy

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_REGEX }
  validates :password, length: { minimum: 8 }, allow_nil: true, if: -> { password_digest_changed? }
  validates :phone, format: { with: PHONE_REGEX }, allow_blank: true

  def rotate_session_token!
    update_column(:session_token, SecureRandom.hex(32))
  end

  def ensure_session_token!
    rotate_session_token! if session_token.blank?
    session_token
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
