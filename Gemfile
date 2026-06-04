# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.3'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache and Action Cable (production only, needs multi-DB)
gem 'solid_cache', group: :production
gem 'solid_cable', group: :production

# Action Cable adapter
gem 'redis', '>= 4.0.1'

# Background jobs
gem 'sidekiq'
gem 'sidekiq-cron'

# Environment variables from .env files
gem 'dotenv-rails'

# App settings (config/settings.yml)
gem 'config'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 1.2'

# User avatars on GCS (optional; local disk when GCS_MEDIA_BUCKET unset)
gem 'google-cloud-storage', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

# Pagination
gem 'kaminari'

# A/B testing (Redis-backed; used for game detail UI variants)
gem 'split', require: 'split/dashboard'

# Transactional email (Resend)
gem 'resend'

# Swagger API documentation
gem 'rswag-api'
gem 'rswag-ui'

# Elasticsearch integration
gem 'elasticsearch-model', '~> 8.0.1'
gem 'elasticsearch-rails', '~> 8.0.1'
gem 'elasticsearch-persistence', '~> 8.0.1'

group :development do
  gem 'bullet'
  gem 'rack-mini-profiler'
end

group :development, :test do
  # RSpec testing framework
  gem 'rspec-rails'

  # Swagger spec generation
  gem 'rswag-specs'

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem 'bundler-audit', require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop-rails-omakase', require: false
end
