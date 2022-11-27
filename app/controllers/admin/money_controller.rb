class Admin::MoneyController < Admin::ApplicationController
  before_action :admin_required, :except => [:doorputer_new_hash, :doorputer_get_dates, :foodputer_data, :stats]
  skip_before_action :verify_authenticity_token, :only => [:doorputer_new_hash, :doorputer_get_dates, :foodputer_data]

  # called by the doorputer when an unknown hash is entered.
  # needs to be called twice with the same hash for the hash to verify

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
