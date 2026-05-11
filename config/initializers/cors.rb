# frozen_string_literal: true

# CORS for browser FE (Next.js). FE_ORIGIN can be comma-separated list.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    fe_origins = ENV.fetch('FE_ORIGIN', 'http://localhost:3001').split(',').map(&:strip)
    origins(*fe_origins)

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: %w[Content-Type]
  end
end
