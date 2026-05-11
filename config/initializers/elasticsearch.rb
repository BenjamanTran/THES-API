# frozen_string_literal: true

# Single switch to disable all Elasticsearch-backed features.
# Set ELASTICSEARCH_ENABLED=true in env to turn back on once the app grows.
Rails.application.config.x.elasticsearch_enabled =
  ActiveModel::Type::Boolean.new.cast(ENV.fetch('ELASTICSEARCH_ENABLED', false))

if Rails.application.config.x.elasticsearch_enabled
  es_client = Elasticsearch::Client.new(
    url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
    log: Rails.env == 'development',
    transport_options: { headers: { 'Content-Type' => 'application/json' } }
  )

  Elasticsearch::Model.client = es_client
end
