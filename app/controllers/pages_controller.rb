class PagesController < ApplicationController
  def home
    # If a user is logged in, grab their record
    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
