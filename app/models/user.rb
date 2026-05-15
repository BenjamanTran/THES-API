# frozen_string_literal: true

class User < ApplicationRecord
  include TokenDigest

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP
  PHONE_REGEX = /\A\+?[0-9\s\-().]{6,20}\z/

  enum :gender, { unspecified: 0, male: 1, female: 2, other: 3 }

  scope :unverified, -> { where(guest: false, email_verified_at: nil) }

  has_secure_password validations: false

  has_many :game_participations, dependent: :destroy
  has_many :games, through: :game_participations
  has_one :rank, dependent: :destroy
  has_many :user_skills, dependent: :destroy

  before_validation :normalize_email

  scope :guests, -> { where(guest: true) }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_REGEX }, unless: :guest?
  validates :password, length: { minimum: 8 }, allow_nil: true, if: -> { password_digest_changed? }
  validates :phone, format: { with: PHONE_REGEX }, allow_blank: true

  def rotate_session_token!
    update_column(:session_token, SecureRandom.hex(32))
  end

  def ensure_session_token!
    rotate_session_token! if session_token.blank?
    session_token
  end

  def email_verified?
    guest? || email_verified_at.present?
  end

  def issue_password_reset_token!
    raw = generate_raw_token
    update_columns(
      password_reset_digest: self.class.digest_token(raw),
      password_reset_sent_at: Time.current
    )
    raw
  end

  def clear_password_reset!
    update_columns(password_reset_digest: nil, password_reset_sent_at: nil)
  end

  def password_reset_valid?(raw)
    return false if raw.blank? || password_reset_digest.blank? || password_reset_sent_at.blank?
    return false if password_reset_sent_at < TOKEN_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(password_reset_digest, self.class.digest_token(raw))
  end

  def issue_email_verification_token!
    raw = generate_raw_token
    update_columns(
      email_verification_digest: self.class.digest_token(raw),
      email_verification_sent_at: Time.current
    )
    raw
  end

  def clear_email_verification!
    update_columns(email_verification_digest: nil, email_verification_sent_at: nil)
  end

  def email_verification_valid?(raw)
    return false if raw.blank? || email_verification_digest.blank? || email_verification_sent_at.blank?
    return false if email_verification_sent_at < VERIFICATION_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(email_verification_digest, self.class.digest_token(raw))
  end

  def verify_email!
    update_columns(
      email_verified_at: Time.current,
      email_verification_digest: nil,
      email_verification_sent_at: nil
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
