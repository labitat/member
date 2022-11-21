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
    mail(to: @user.email, subject: "Labitat signup verification")
  end
end
