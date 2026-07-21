class User < ApplicationRecord
  def self.find_or_create_from_omniauth(auth)
    # 1. Search for existing user
    user = find_by(provider: auth.provider, uid: auth.uid)

    if user
      # User already exists, return them directly
      user
    else
      # Create and set attributes for new user
      new_user = User.new
      new_user.provider   = auth.provider
      new_user.uid        = auth.uid
      new_user.email      = auth.info.email
      new_user.avatar_url = auth.info.image
      new_user.username   = auth.info.name.presence || auth.info.email.split("@").first

      # Save to database and return the user instance
      new_user.save
      new_user
    end
  end
end