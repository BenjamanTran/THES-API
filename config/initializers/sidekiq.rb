# frozen_string_literal: true

require 'sidekiq/web'

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_sidekiq_session'

redis_config = {
  url: "redis://#{ENV.fetch('REDIS_HOST', 'localhost')}:#{ENV.fetch('REDIS_PORT', 6379)}/#{ENV.fetch('REDIS_DB', 0)}"
}

Sidekiq.configure_server do |config|
  config.redis = redis_config

  config.on(:startup) do
    schedule = {
      'update_game_statuses' => {
        'cron' => '*/50 * * * *',
        'class' => 'Games::UpdateStatusesJob',
        'description' => 'Transition game statuses based on time (open/full -> ongoing -> finished)'
      },
      'cleanup_expired_guests' => {
        'cron' => '0 3 * * *',
        'class' => 'Users::CleanupGuestsJob',
        'description' => 'Delete guest accounts older than 30 days and all related data'
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

Sidekiq.default_job_options['retry'] = 1
