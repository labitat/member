class MoneyController < ApplicationController
  # layout "user_wide"
  before_action :admin_required, :except => [:doorputer_new_hash, :doorputer_get_dates, :foodputer_data, :stats]
  skip_before_action :verify_authenticity_token, :only => [:doorputer_new_hash, :doorputer_get_dates, :foodputer_data]

  # called by the doorputer when an unknown hash is entered.
  # needs to be called twice with the same hash for the hash to verify
  def doorputer_new_hash
    if (request.protocol != "https://") && !Settings["insecure"]
      render :text => "only https allowed", :status => 403
      return
    end

    if params["key"] != Settings["doorputer_key"]
      render :text => "wrong key", :status => 403
      return
    end

    if !params["hash"]
      render :text => "no hash received", :status => 403
      return
    end

    door_hash = DoorHash.find(:first, :conditions => ["value = ?", params["hash"]])

    if door_hash
      # has less than the time-out delay passed?
      if (Time.now - door_hash.created).to_i < Settings["doorputer_verify_max_delay"]
        door_hash.verified = true
        door_hash.created = Time.now
        door_hash.save!
        render :text => "hash verified", :status => 202 # accepted
        return
      else
        door_hash.destroy
        render :text => "timeout passed, you'll have to start over", :status => 403
        return
      end
    else # hash doesn't exist. a new hash will be created
      door_hash = DoorHash.new

      door_hash.value = params["hash"]
      door_hash.created = Time.now
      door_hash.save!

      render :text => "new hash created", :status => 201 # created
      return
    end
  end

  # called by the doorputer to retrieve login names, hashes and their expiration dates
  def doorputer_get_dates
    if (request.protocol != "https://") && !Settings["insecure"]
      render :text => "only https allowed", :status => 403
      return
    end

    if params["key"] != Settings["doorputer_key"]
      render :text => "wrong key", :status => 403
      return
    end

    users = User.find(:all, :order => "login asc")

    fmt = "%Y-%m-%d"

    v = Value.find_by_name("bank_data_last_updated")
    bank_data_last_updated = Date.strptime(v.value, fmt)
    today = Date.strptime(Time.now.strftime(fmt), fmt)

    data = []

    users.each do |user|
      if user.door_hash && (user.door_hash != "")
        next if !user.paid_until

        # make sure door access doesn't expire because the bank data hasn't been uploaded recently

        # if the user paid until some time after the last bank data update, but before today
        # then the new monthly transfer has likely been received by the bank
        # but has not been uploaded to the system
        if (user.paid_until >= bank_data_last_updated) && (user.paid_until < today)
          paid_until = today
        else
          paid_until = user.paid_until
        end

        data << { "login" => user.login, "expiry_date" => paid_until, "hash" => user.door_hash }
      end
    end

    render :text => data.to_json
  end

  # XXX no longer used
  # called by the foodputer to send new card-hashes
  def foodputer_data
    if (request.protocol != "https://") && !Settings["insecure"]
      render :text => "only https allowed", :status => 403
      return
    end

    if !request.post?
      render :text => "only post allowed", :status => 403
      return
    end

    key = params["key"]
    login = params["login"]
    cardhash = params["cardhash"]

    if key != Settings["foodputer_key"]
      render :text => "wrong password", :status => 403
      return
    end

    user = User.find_by_login(login)

    if !user
      render :text => "user not found", :status => 403
      return
    end

    user.card_only_hash = cardhash
    user.save!

    render :text => "Card-hash successfully updated"
  end

  def index
  end

  # upload raw payment html data from bank
  def upload_bankdata
  end

  def confirm_bankdata
    if !request.post?
      redirect_to "upload_bankdata"
      return
    end

    if !params["bankdata"] || (params["bankdata"] == "")
      flash[:notice] = "No bank data entered"
      redirect_to :back
      return
    end

    raw_payments = Payment.parse_payments(params["bankdata"])

    @payments = []
    raw_payments.each do |payment|
      if payment.amount >= 150
        if !payment.find_dupe
          @payments << payment
        end
      end
    end

    @users = User.find(:all, :order => "login asc")
  end

  def save_bankdata
    if !params["payment"]
      render :text => "no data"
      return
    end

    @payments = []

    params["payment"].each_value do |pay|
      if pay["user_id"].to_i == 0
        next
      end

      payment = Payment.new
      payment.comment = pay["comment"]
      payment.received = Date.strptime(pay["received"], "%Y-%m-%d")
      payment.amount = pay["amount"].to_f
      payment.user_id = pay["user_id"].to_i
      payment.source = "bank transfer"

      payment.save!
      @payments << payment
    end

    v = Value.find_by_name("bank_data_last_updated")
    v.value = Time.now.strftime("%Y-%m-%d")
    v.save!

    # update "paid until" date fields for all users
    User.paid_until_update
  end

  def stats
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)

    @users = User.find(:all, :conditions => ["paid_until >= ?", today])

    render :text => "Paying: #{@users.length}"
  end

  def new_payment
    @users = User.find(:all, :order => "login asc")

    @payment = Payment.new
  end

  def edit_payment
    @users = User.find(:all, :order => "login asc")

    if params["id"]
      @payment = Payment.find(params["id"])
    else
      @payment = Payment.new
    end

    return if !request.post?

    @payment.attributes = params["payment"]

    begin
      @payment.save!
    rescue ActiveRecord::RecordInvalid => e
      flash["notice"] = "You missed a spot!"
      return
    end

    User.paid_until_update

    if params["id"]
      flash["notice"] = "Changes saved!"
    else
      flash["notice"] = "New payment created!"
    end
  end

  def destroy_payment
    @payment = Payment.find(params["id"])
    @payment.destroy
    flash["notice"] = "Payment deleted!"
    redirect_to :action => "search_payments"
  end

  def search_payments
    @params = params
    @limit = nil

    conds = []

    if params["from_date"] && (!params["from_date"].empty?)
      if params["to_date"] && (!params["to_date"].empty?)
        conds << "payments.received >= #{q(params["from_date"])} AND payments.received <= #{q(params["to_date"])}"
      else
        conds << "payments.received = #{q(params["from_date"])}"
      end
    end

    if params["from_amount"] && (!params["from_amount"].empty?)
      if params["to_amount"] && (!params["to_amount"].empty?)
        conds << "payments.amount >= #{q(params["from_amount"])} AND payments.amount <= #{q(params["to_amount"])}"
      else
        conds << "payments.amount = #{q(params["from_amount"])}"
      end
    end

    if params["login"] && (!params["login"].empty?)
      conds << "users.login like #{q("%" + params["login"].gsub(/\s+/, "%") + "%")}"
    end

    if params["name"] && (!params["name"].empty?)
      conds << "users.name like #{q("%" + params["name"].gsub(/\s+/, "%") + "%")}"
    end

    if conds.length == 0
      @limit = 20
    end

    @payments = Payment.find(:all,
                             :conditions => conds.join(" AND "),
                             :include => :user,
                             :limit => @limit,
                             :order => "payments.received desc")
  end
end
