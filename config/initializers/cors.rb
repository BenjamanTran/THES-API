# frozen_string_literal: true

allowed = ENV['FE_ORIGIN'].to_s.chomp('/').presence || 'http://localhost:3001'

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins allowed, 'http://localhost:3001', 'http://localhost:3000'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end
