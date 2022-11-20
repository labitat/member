class RegistrationController < ApplicationController
  def index
    redirect_to :action => "signup"
  end

  def forgot_password
    return unless request.post?

    if !params[:email]
      flash.now[:notice] = "You need to supply your email address!"
      return
    end

    @user = User.find_by_email(params[:email], :first)

    if !@user
      @complete = true # fake response, to avoid fishing
      return
    end

    @user.generate_forgot_password_token

    Notifier.deliver_forgot_password(@user.email, @user.forgot_password_token)

    @complete = true
  end

  def change_password
    # extend this to include non-forgotten email type responses

    if !params[:token]
      flash.now[:notice] = "Error: No token given"
      return
    end

    @user = User.find_by_forgot_password_token(params[:token])

    if !@user
      flash.now[:notice] = "Error: No token given"
      return
    end

    if @user.forgot_password_expires < Time.now
      flash.now[:notice] = "Error: Token has expired"
      @user = nil
      return
    end

    return unless request.post?

    if !(params[:password] and params[:password2] and params[:password] == params[:password2])
      flash.now[:notice] = "Error: Invalid password (empty or not equal)"
      return
    end

    @user.change_password(params[:password])

    flash.now[:notice] = "Password change successful. #{@template.link_to "Please log in.", :controller => "main", :action => "index"}"

    @user = nil
  end

  def stats
    @num_total_members = User.select("verified = 1 AND blocked = 0").count

    # find all the paying users
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)
    paying_users = User.find(:all, :conditions => ["paid_until >= ?", today])
    @num_actual_paying = paying_users.length
  end

  def new
    @user = User.new
    @paying_member_goal = Value.find_by_name("paying_member_goal").value.to_i
    @member_fee = Value.find_by_name("monthly_fee").value.to_i
  end

  def create
    @user = User.new(user_params)
    @paying_member_goal = Value.find_by_name("paying_member_goal").value.to_i
    @member_fee = Value.find_by_name("monthly_fee").value.to_i
    @user.verified = false
    @user.auth_code = User.generate_random_password(16)

    if @user.valid?
      @user.save!
      NotifierMailer.with(user: @user).signup_verification.deliver_now
      self.current_user = User.authenticate(@user.email, params[:user][:password])
      redirect_to signup_thanks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
  end

  def verify_signup
    @auth_code = params[:code]

    # only allow alphanumeric characters
    if @auth_code.gsub(/(\d|\w).*/, "") != ""
      redirect_to :action => "verify_error"
      return
    end

    @user = User.find(
      :first,
      :conditions => ["auth_code = ?", @auth_code],
    )

    if !@user
      redirect_to :action => "verify_error"
      return
    end

    return if !request.post?

    if !@user.authenticated?(params[:password], true)
      redirect_to :action => "verify_error"
      return
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password]

    @user.verify!

    Notifier.deliver_signup_congrats(@user)

    redirect_to :action => "verify_signup_complete"
  end

  def verify_signup_complete
  end

  def verify_error
  end

  def verify_email
    @auth_code = params[:code]

    # only allow alphanumeric characters
    if @auth_code.gsub(/(\d|\w).*/, "") != ""
      redirect_to :action => "verify_error"
      return
    end

    @user = User.find(
      :first,
      :conditions => ["auth_code = ?", @auth_code],
    )

    if !@user
      redirect_to :action => "verify_error"
      return
    end

    return if !request.post?

    if !@user.authenticated?(params[:password], true)
      redirect_to :action => "verify_error"
      return
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password]

    @user.change_email!

    Notifier.deliver_email_change_congrats(@user.email)

    redirect_to :action => "verify_email_complete"
  end

  private

  def user_params
    params.require(:user).permit(:login, :email, :password, :password_confirmation, :name, :phone, :mailing_list)
  end
end
