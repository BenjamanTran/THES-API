# frozen_string_literal: true

require 'vips'

module Users
  class AvatarProcessor
    MAX_BYTES = 5.megabytes
    OUTPUT_SIZE = 256
    WEBP_QUALITY = 80
    ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze

    class Error < StandardError; end

    def self.call(file:)
      new(file:).call
    end

    def initialize(file:)
      @file = file
    end

    def call
      raise Error, 'Không có file ảnh' if @file.blank?

      validate_uploaded_file!
      data = read_upload_body
      raise Error, 'Ảnh quá lớn (tối đa 5MB)' if data.bytesize > MAX_BYTES

      process_to_webp(data)
    rescue ::Vips::Error
      raise Error, 'File ảnh không hợp lệ'
    rescue LoadError
      raise Error, 'Thiếu libvips trên server — cài libvips-dev (Docker) hoặc vips (macOS)'
    end

    private

    def validate_uploaded_file!
      content_type = @file.content_type.to_s.split(';').first.strip
      return if ALLOWED_TYPES.include?(content_type)

      raise Error, 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP'
    end

    def read_upload_body
      io = @file.respond_to?(:tempfile) ? @file.tempfile : @file
      io.rewind
      data = io.read
      io.rewind
      data
    end

    def process_to_webp(data)
      image = Vips::Image.new_from_buffer(data, '')
      raise Error, 'Ảnh quá nhỏ (tối thiểu 64×64)' if image.width < 64 || image.height < 64

      square = image.thumbnail_image(OUTPUT_SIZE, height: OUTPUT_SIZE, crop: :centre)
      square.webpsave_buffer(Q: WEBP_QUALITY)
    end
  end
end
