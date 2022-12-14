class Admin::MoneyController < Admin::ApplicationController
  def index
  end

  # upload raw payment html data from bank
  def upload
  end

  def confirm_bankdata
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

    @users = User.all.order("login asc")
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

    v = Value.find_or_initialize_by(name: "bank_data_last_updated")
    v.value = Time.now.strftime("%Y-%m-%d")
    v.save!

    # update "paid until" date fields for all users
    User.paid_until_update!
  end

  def stats
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)

    count = User.where(["paid_until >= ?", today]).count

    render plain: "Paying: #{count}"
  end

  def new_payment
    @users = User.all.order("login asc")

    @payment = Payment.new
  end

  def create_payment
    @payment = Payment.new(payment_params)
    if @payment.save
      flash[:notice] = "Payment created!"
      redirect_to admin_money_path
    else
      render :new_payment
    end
  end

  def edit_payment
    @payment = Payment.find(params[:id])
  end

  def update_payment
    @payment = Payment.find(params[:id])
    @payment.update(payment_params)

    if @payment.save
      User.paid_until_update!
      flash[:notice] = "Payment updated!"
      redirect_to admin_money_path
    else
      render :edit_payment
    end
  end

  def destroy_payment
    @payment = Payment.find(params["id"])
    @payment.destroy
    flash["notice"] = "Payment deleted!"
    redirect_to :action => "search_payments"
  end

  def search_payments
  end

  def payment_search_results
    conds = []
    vars = []
    if params["from_date"].present?
      vars << params["from_date"]
      if params["to_date"].present?
        conds << "payments.received >= ? AND payments.received <= ?"
        vars << params["to_date"]
      else
        conds << "payments.received = ?"
      end
    end

    if params["from_amount"].present?
      vars << params["from_amount"]
      if params["to_amount"].present?
        vars << params["to_amount"]
        conds << "payments.amount >= ? AND payments.amount <= ?"
      else
        conds << "payments.amount = ?"
      end
    end

    if params["login"].present?
      vars << "%#{ActiveRecord::Base.send(:sanitize_sql_like, params["login"])}%"
      conds << "users.login like ?"
    end

    if params["name"] && (!params["name"].empty?)
      vars << "%#{ActiveRecord::Base.send(:sanitize_sql_like, params["name"])}%"
      conds << "users.name like ?"
      conds << "users.name like #{q("%" + params["name"].gsub(/\s+/, "%") + "%")}"
    end

    @payments = (conds.empty? ? Payment : Payment.where([conds.join(" AND "), *conds])).includes(:user).order("payments.received desc").page params[:page]
  end

  private

  def payment_params
    params.require(:payment).permit(:user_id, :amount, :received, :source)
  end
end
