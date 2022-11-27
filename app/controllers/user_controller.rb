class UserController < ApplicationController
  before_action :login_required, except: [:radius_hashes]
  skip_before_action :verify_authenticity_token, only: [:radius_hashes]

  def radius_hashes
    if params["key"] != Rails.configuration.radius_key
      return render plain: "wrong key", status: 403
    end

    hashes = User.verified.all.map do |user|
      "#{user.login} ASSHA-Password := \"#{user.crypted_password}#{user.salt}\"\n"
    end
    render plain: hashes.join
  end

  def index
    @user = current_user
  end

  def info
    @user = current_user
  end

  def list_hashes
    @user = current_user
    @hashes = DoorHash.find(:all, :order => "created desc", :limit => 5)
  end

  def claim_hash
    door_hash = DoorHash.find(params["id"])

    if !door_hash
      flash["notice"] = "Looks like the card+pin info you are trying to claim has disappeared"
      redirect_to :action => "list_hashes"
      return
    end

    current_user.door_hash = door_hash.value
    current_user.save!

    door_hash.destroy

    flash["notice"] = "Successfully claimed card+pin info. You will be granted access to the space within the next 10 minutes."
    redirect_to :action => "info"
  end

  def clear_hash
    current_user.door_hash = ""
    current_user.save!
    flash["notice"] = "Card+pin info cleared"
    redirect_to :action => "list_hashes"
  end

  def irc_re_reg
    return unless request.post?

    if !params[:password]
      flash.now[:notice] = "You need to supply a password"
      return
    end

    if !current_user.authenticated?(params[:password])
      flash.now[:notice] = "Wrong password!"
      return
    end

    current_user.password = params[:password]
    current_user.irc_register_account

    flash.now[:notice] = "Your account is now registered on IRC"
  end

  def list_signup
    if !params[:list]
      return
    end
    current_user.mailman_register(params[:list])
    redirect_to :controller => "main", :action => "index"
  end

  def list_signoff
    if !params[:list]
      return
    end
    current_user.mailman_unregister(false, params[:list])
    redirect_to :controller => "main", :action => "index"
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

  def signup
    @user = User.new

    @num_total_members = User.select("verified = 1 AND blocked = 0").count

    # find all the paying users
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)
    paying_users = User.where(["paid_until >= ?", today])

    @num_actual_paying = paying_users.count

    @paying_member_goal = Value.find_by_name("paying_member_goal").value.to_i
    @member_fee = Value.find_by_name("monthly_fee").value.to_i

    @members_bar_width = ((@num_actual_paying.to_f / @paying_member_goal) * 300).to_i
  end

  def create
    @user = User.new

    @num_total_members = User.select("verified = 1 AND blocked = 0").count

    # find all the paying users
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)
    paying_users = User.where(["paid_until >= ?", today])

    @num_actual_paying = paying_users.count

    @paying_member_goal = Value.find_by_name("paying_member_goal").value.to_i
    @member_fee = Value.find_by_name("monthly_fee").value.to_i

    @members_bar_width = ((@num_actual_paying.to_f / @paying_member_goal) * 300).to_i

    @user.attributes = params[:user]
    @user.login = params[:user][:login]
    @user.verified = false

    @user.auth_code = User.generate_random_password(16)

    begin
      @user.save_with_captcha!
    rescue ActiveRecord::RecordInvalid => e
      return
    end

    Notifier.deliver_signup_verification(@user.email, @user.auth_code)

    redirect_to :action => "signup_thanks", :id => @user.id
  end

  def signup_thanks
    @user = User.find(params[:id])
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

  def upload_ssh_key
    if params["file"].blank?
      flash[:notice] = "You must choose a file for upload"
      redirect_to :action => "upload"
      return
    end

    dest_dir = Setting["gitolite_admin_path"] + "/keydir/"
    tmp_dest_dir = "#{RAILS_ROOT}/private/tmp/"

    filename = self.class.sanitize_filename(params["file"].original_filename)
    new_filename = "#{current_user.login}.pub"
    filepath = tmp_dest_dir + new_filename

    if FileTest.file?(filepath)
      FileUtils.rm(filepath)
    end

    File.open(filepath, "wb") do |f|
      f.write(params["file"].read)
    end

    if !FileTest.file?(filepath)
      flash["notice"] = "error uploading file"
      return
    end

    FileUtils.mv(filepath, dest_dir + new_filename)

    # XXX gitolite ssh key adder in this dir

    # go to gitolite_admin_path and
    # git add the new file
    # git commit -a -m "adding ssh key for user #{current_user.login}"
    # git push

  end

  # not currently used
  def edit
    @user = current_user

    @user.new_email = @user.email

    @member_fee = Value.find_by_name("monthly_fee").value.to_i

    return if !request.post?

    @user.attributes = params[:user]

    if (@user.new_email != "") && (@user.new_email != @user.email)
      flash[:notice] = "You have changed you email. The change will not be complete before you click the authentication link sent to your new email."

      @user.auth_code = User.generate_random_password(16)

      begin
        @user.save!
      rescue ActiveRecord::RecordInvalid => e
        return
      end

      Notifier.deliver_email_verification(@user.new_email, @user.auth_code)
    else
      begin
        @user.save!
      rescue ActiveRecord::RecordInvalid => e
        return
      end
    end
  end

  def payment_info
    @monthly_fee = Value.find_by_name("monthly_fee").value.to_i
  end
end
