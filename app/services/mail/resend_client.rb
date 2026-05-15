# frozen_string_literal: true

module Mail
  class ResendClient
    class << self
      def deliver(to:, subject:, html:)
        api_key = ENV.fetch('RESEND_API_KEY', nil)
        if api_key.blank?
          Rails.logger.warn("[Resend] Skipped email to #{to}: RESEND_API_KEY not set")
          return false
        end

        from = ENV.fetch('MAIL_FROM', 'SmashHub <noreply@smashhub88.win>')
        Resend::Emails.send({
                              from: from,
                              to: [to],
                              subject: subject,
                              html: html
                            })
        true
      rescue StandardError => e
        Rails.logger.error("[Resend] Failed to send to #{to}: #{e.message}")
        false
      end

      def frontend_url(path)
        base = ENV.fetch('FE_ORIGIN', 'http://localhost:3001').to_s.chomp('/')
        "#{base}#{path}"
      end
    end
  end
end
