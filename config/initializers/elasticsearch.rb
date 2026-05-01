# frozen_string_literal: true

es_client = Elasticsearch::Client.new(
  url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
  log: Rails.env == 'development',
  transport_options: { headers: { 'Content-Type' => 'application/json' } }
)

# ES 8.x gem checks for product header (X-elastic-product).
# When xpack.security.enabled=false, this header is missing — bypass the check.
if es_client.respond_to?(:instance_variable_set)
  es_client.instance_variable_set(:@verified, true)
  transport = es_client.transport
  transport.instance_variable_set(:@verified, true) if transport.respond_to?(:instance_variable_set)
end

Elasticsearch::Model.client = es_client
