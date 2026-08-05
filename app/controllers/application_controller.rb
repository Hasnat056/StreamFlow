class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  def authenticate_user!
    unless current_user
      redirect_to root_path, alert: "You must be signed in to do that."
    end
  end

  def user_not_authorized
    redirect_to root_path, alert: "You're not authorized to do that."
  end
end
