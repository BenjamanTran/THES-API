# frozen_string_literal: true

module Users
  class DeleteAvatarService < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      old_key = @user.avatar_key
      @user.update!(avatar_key: nil, avatar_url: nil)
      AvatarStorage.delete(old_key)

      success(user: @user)
    end
  end
end
