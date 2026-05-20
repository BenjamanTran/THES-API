# frozen_string_literal: true

# Google client libraries dump full HTTP/Faraday responses at DEBUG — very noisy on every avatar view.
unless ENV['GCS_DEBUG'] == 'true'
  require 'logger'

  if defined?(Google::Apis)
    Google::Apis.logger = Logger.new(File::NULL)
    Google::Apis.logger.level = Logger::WARN
  end

  if defined?(Google::Cloud::Storage)
    Google::Cloud::Storage.configure do |config|
      config.project_id ||= ENV['GCS_PROJECT_ID'].presence
    end
  end
end

module GcsCredentials
  module_function

  def valid_file?(path)
    return false unless path.file?
    return false if path.size.zero?

    data = JSON.parse(path.read)
    data.is_a?(Hash) && data['type'].present?
  rescue JSON::ParserError
    false
  end
end

# Normalizes GOOGLE_APPLICATION_CREDENTIALS when set and valid.
# Invalid/empty files are cleared so the client falls back to Application Default Credentials.
if ENV['GCS_MEDIA_BUCKET'].present?
  creds = ENV['GOOGLE_APPLICATION_CREDENTIALS'].to_s.strip
  if creds.blank?
    Rails.logger.info '[GCS] GCS_MEDIA_BUCKET set; using Application Default Credentials (no key file)'
  else
    path = Pathname.new(creds)
    path = Rails.root.join(creds) unless path.absolute?
    path = path.expand_path

    if GcsCredentials.valid_file?(path)
      ENV['GOOGLE_APPLICATION_CREDENTIALS'] = path.to_s
      Rails.logger.info "[GCS] Credentials: #{path}"
    else
      ENV.delete('GOOGLE_APPLICATION_CREDENTIALS')
      Rails.logger.warn "[GCS] Ignoring invalid credentials at #{path}; using ADC"
    end
  end
end
