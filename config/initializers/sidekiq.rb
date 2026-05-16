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
    # Feb 31 never exists — cleanup crons stay registered but never fire.
    # Enqueue manually from Sidekiq Web when needed.
    never_cron = '0 0 31 2 *'

    schedule = {
      'update_game_statuses' => {
        'cron' => '0 * * * *',
        'timezone' => 'Asia/Ho_Chi_Minh',
        'class' => 'Games::UpdateStatusesJob',
        'description' => 'Transition game statuses based on time (open/full -> ongoing -> finished)'
      },
      'cleanup_expired_guests' => {
        'cron' => never_cron,
        'timezone' => 'Asia/Ho_Chi_Minh',
        'class' => 'Users::CleanupGuestsJob',
        'description' => 'Manual only (Feb 31). Delete guest accounts older than 30 days'
      },
      'cleanup_unverified_users' => {
        'cron' => never_cron,
        'timezone' => 'Asia/Ho_Chi_Minh',
        'class' => 'Users::CleanupUnverifiedUsersJob',
        'description' => 'Manual only (Feb 31). Delete unverified accounts after 30 days'
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

Sidekiq.default_job_options['retry'] = 1
