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
    @hashes = DoorHash.all.order("created_at desc").limit(5)
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

  def list_signup
    if !params[:list]
      return
    end
    current_user.mailman_register(params[:list])
    redirect_to root_path
  end

  def list_signoff
    if !params[:list]
      return
    end
    current_user.mailman_unregister(false, params[:list])
    redirect_to root_path
  end

  def stats
    @num_total_members = User.select("verified = 1 AND blocked = 0").count

    # find all the paying users
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)
    paying_users = User.find(:all, :conditions => ["paid_until >= ?", today])
    @num_actual_paying = paying_users.length
  end

  def payment_info
    @monthly_fee = Value.find_by_name("monthly_fee").value.to_i
  end
end
