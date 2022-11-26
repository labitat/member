class NotifierMailer < ApplicationMailer
  default from: "noreply@labitat.dk"

  def signup_verification
    @user = params[:user]
    @verify_url = verify_signup_url(code: @user.auth_code)
    mail(to: @user.email, subject: "Labitat signup verification")
  end

  def signup_congrats
    @user = params[:user]
    @site_url = "https://labitat.dk/"
    mail(to: @user.email, subject: "Welcome to Labitat!")
  end

  def forgot_password
    @user = params[:user]
    @token_link = change_password_url(t: @user.forgot_password_token)
    mail(to: @user.email, subject: "Password reset for Labitat")
  end
end
