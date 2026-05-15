# frozen_string_literal: true

module Mail
  class UserMailer
    class << self
      def password_reset(user, raw_token)
        link = ResendClient.frontend_url("/reset-password?token=#{raw_token}")
        ResendClient.deliver(
          to: user.email,
          subject: 'Đặt lại mật khẩu SmashHub',
          html: <<~HTML
            <p>Xin chào #{ERB::Util.html_escape(user.name)},</p>
            <p>Bạn vừa yêu cầu đặt lại mật khẩu. Nhấn link bên dưới (hết hạn sau 1 giờ):</p>
            <p><a href="#{link}">Đặt lại mật khẩu</a></p>
            <p>Nếu không phải bạn, hãy bỏ qua email này.</p>
          HTML
        )
      end

      def email_verification(user, raw_token)
        link = ResendClient.frontend_url("/verify-email?token=#{raw_token}")
        ResendClient.deliver(
          to: user.email,
          subject: 'Xác nhận tài khoản SmashHub',
          html: <<~HTML
            <p>Xin chào #{ERB::Util.html_escape(user.name)},</p>
            <p>Cảm ơn bạn đã đăng ký SmashHub. Nhấn link để xác nhận email (hết hạn sau 48 giờ):</p>
            <p><a href="#{link}">Xác nhận email</a></p>
          HTML
        )
      end
    end
  end
end
