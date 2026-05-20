# frozen_string_literal: true

module Users
  class AvatarStorage
    class Error < StandardError; end

    def self.upload(user_id:, body:)
      key = "avatars/#{user_id}/#{SecureRandom.uuid}.webp"
      if gcs_configured?
        gcs_upload(key, body)
      else
        local_upload(key, body)
      end
      [key, public_url(key)]
    end

    def self.delete(key)
      return if key.blank?

      if gcs_configured?
        gcs_delete(key)
      else
        local_delete(key)
      end
    end

    def self.public_url(key)
      base = api_public_base
      "#{base}/avatars/#{key.delete_prefix('avatars/')}"
    end

    def self.display_url_for(user)
      key = user.avatar_key.presence
      return public_url(key) if key.present?

      user.avatar_url
    end

    def self.download(key)
      if gcs_configured?
        gcs_download(key)
      else
        local_download(key)
      end
    end

    def self.api_public_base
      ENV.fetch('API_PUBLIC_URL', 'http://localhost:3000').chomp('/')
    end

    def self.gcs_configured?
      ENV['GCS_MEDIA_BUCKET'].present?
    end

    def self.local_root
      Rails.root.join('public', 'avatars')
    end

    def self.local_upload(key, body)
      path = local_root.join(key.delete_prefix('avatars/'))
      FileUtils.mkdir_p(path.dirname)
      File.binwrite(path, body)
    end

    def self.local_delete(key)
      path = local_root.join(key.delete_prefix('avatars/'))
      File.delete(path) if path.exist?
    rescue Errno::ENOENT
      nil
    end

    def self.local_download(key)
      path = local_root.join(key.delete_prefix('avatars/'))
      return unless path.file?

      File.binread(path)
    end

    def self.gcs_download(key)
      file = gcs_bucket&.file(key)
      return unless file

      io = file.download
      io = io.first if io.is_a?(Array)
      io.respond_to?(:read) ? io.read : io.to_s
    end

    def self.gcs_upload(key, body)
      bucket = gcs_bucket
      raise Error, 'GCS bucket không tồn tại' unless bucket

      bucket.create_file StringIO.new(body), key, content_type: 'image/webp'
    rescue LoadError
      raise Error, 'Thiếu gem google-cloud-storage — chạy bundle install'
    end

    def self.gcs_delete(key)
      file = gcs_bucket&.file(key)
      file&.delete
    rescue LoadError
      nil
    end

    def self.gcs_bucket
      storage_client.bucket ENV.fetch('GCS_MEDIA_BUCKET')
    end

    def self.storage_client
      require 'google/cloud/storage'

      opts = {}
      opts[:project_id] = gcs_project_id if gcs_project_id.present?
      creds = gcs_credentials_path
      opts[:credentials] = creds if creds.present?

      Google::Cloud::Storage.new(**opts)
    rescue JSON::ParserError
      raise Error, 'File credentials Google không hợp lệ — xóa GOOGLE_APPLICATION_CREDENTIALS hoặc chạy gcloud auth application-default login'
    end

    # Path to credentials JSON when valid; nil → ADC (gcloud login / Workload Identity).
    def self.gcs_credentials_path
      path = ENV['GOOGLE_APPLICATION_CREDENTIALS'].to_s.strip
      return if path.blank?

      full = Pathname.new(path)
      full = Rails.root.join(path) unless full.absolute?
      full = full.expand_path
      return unless GcsCredentials.valid_file?(full)

      full.to_s
    end

    def self.gcs_project_id
      ENV['GCS_PROJECT_ID'].presence
    end
  end
end
