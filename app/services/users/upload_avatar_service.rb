# frozen_string_literal: true

module Users
  class UploadAvatarService < ApplicationService
    def initialize(user:, file:)
      @user = user
      @file = file
    end

    def call
      webp = AvatarProcessor.call(file: @file)
      old_key = @user.avatar_key

      key, url = AvatarStorage.upload(user_id: @user.id, body: webp)
      @user.update!(avatar_key: key, avatar_url: url)
      AvatarStorage.delete(old_key)

      success(user: @user)
    rescue AvatarProcessor::Error, AvatarStorage::Error => e
      failure(e.message)
    end
  end
end
