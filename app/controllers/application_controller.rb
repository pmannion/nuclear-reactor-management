class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :current_user
  before_action :require_login

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def require_login
    unless @current_user
      redirect_to login_path
    end
  end

  def logged_in?
    !!@current_user
  end

  helper_method :current_user, :logged_in?
end
