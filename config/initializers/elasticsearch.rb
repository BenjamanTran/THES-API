# frozen_string_literal: true

es_client = Elasticsearch::Client.new(
  url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
  log: Rails.env == 'development',
  transport_options: { headers: { 'Content-Type' => 'application/json' } }
)

Elasticsearch::Model.client = es_client
