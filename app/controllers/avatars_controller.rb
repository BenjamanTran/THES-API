# frozen_string_literal: true

# Serves avatar WebP files (local disk or proxied from private GCS).
class AvatarsController < ApplicationController
  CACHE_HEADERS = { type: 'image/webp', disposition: 'inline', cache_control: 'public, max-age=31536000, immutable' }.freeze

  def show
    return head :not_found unless valid_params?

    key = "avatars/#{params[:user_id]}/#{params[:filename]}"
    body = Users::AvatarStorage.download(key)
    return head :not_found if body.blank?

    send_data body, **CACHE_HEADERS
  end

  private

  def valid_params?
    params[:user_id].to_s.match?(/\A\d+\z/) &&
      params[:filename].to_s.match?(/\A[a-f0-9-]+\.webp\z/i)
  end
end
