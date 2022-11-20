class NotifierMailer < ApplicationMailer
  default from: "noreply@labitat.dk"

  def signup_verification
    @user = params[:user]
    mail(to: @user.email, subject: "Labitat signup verification", verification_link: verify_signup_url(code: @user.auth_code))
  end
end
