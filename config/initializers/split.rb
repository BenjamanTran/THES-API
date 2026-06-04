# frozen_string_literal: true

return unless defined?(Split)

redis_host = ENV.fetch('REDIS_HOST', 'localhost')
redis_port = ENV.fetch('REDIS_PORT', 6379)
redis_db = ENV.fetch('REDIS_DB', 0)

experiments_path = Rails.root.join('config/experiments.yml')
experiments_config =
  if File.exist?(experiments_path)
    YAML.safe_load_file(experiments_path)
  else
    {}
  end

Split.configure do |config|
  config.redis = "redis://#{redis_host}:#{redis_port}/#{redis_db}"
  config.allow_multiple_experiments = true
  config.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SPLIT_ENABLED', 'true'))
  config.experiments = experiments_config
end
