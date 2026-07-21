class SessionsController < ApplicationController
  def omniauth
    auth = request.env["omniauth.auth"]
    puts auth
    user = User.find_or_create_from_omniauth(auth)

    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in successfully!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out!"
  end
end
