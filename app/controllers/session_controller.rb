# This controller handles the login/logout function of the site.
class SessionController < ApplicationController
  def new
  end

  def create
    user = User.authenticate(params[:login], params[:password], true)
    if user.nil?
      flash.now[:error] = "Login error"
      render :new, status: 400
    elsif user.verified?
      self.current_user = user
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at }
      end
      flash[:notice] = "Login successful"
      redirect_to root_path
    else
      flash.now[:error] = "You must verify your email address before logging in"
      render :new, status: 400
    end
  end

  def destroy
    self.current_user.forget_me! if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => "session", :action => "new")
  end
end
