# frozen_string_literal: true

module TokenDigest
  extend ActiveSupport::Concern

  TOKEN_TTL = 1.hour
  VERIFICATION_TTL = 48.hours

  class_methods do
    def digest_token(raw)
      Digest::SHA256.hexdigest(raw)
    end
  end

  def generate_raw_token
    SecureRandom.urlsafe_base64(32)
  end
end
