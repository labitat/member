class DoorController < ApplicationController
  before_action :require_doorputer_key

  def new_hash
    if !params["hash"]
      return render plain: "no hash received", :status => 403
    end

    if door_hash = DoorHash.find_by_value(params["hash"])
      # has less than the time-out delay passed?
      if door_hash.created_at + Rails.configuration.doorputer_verify_max_delay.seconds > Time.now
        door_hash.verified = true
        door_hash.save!
        render plain: "hash verified", status: 202 # accepted
      else
        door_hash.destroy
        render plain: "timeout passed, you'll have to start over", status: 403
      end
    else # hash doesn't exist. a new hash will be created
      DoorHash.create!(value: params["hash"], verified: false)
      render plain: "new hash created", status: 201
    end
  end

  # called by the doorputer to retrieve login names, hashes and their expiration dates
  def list
    users = User.where(["paid_until IS NOT NULL AND door_hash IS NOT NULL AND door_hash != ?", ""]).order("login asc")

    fmt = "%Y-%m-%d"
    v = Value.find_by_name("bank_data_last_updated")
    bank_data_last_updated = Date.strptime(v.value)
    today = Time.now
    data = users.map do |user|
      # make sure door access doesn't expire because the bank data hasn't been uploaded recently

      # if the user paid until some time after the last bank data update, but before today
      # then the new monthly transfer has likely been received by the bank
      # but has not been uploaded to the system
      paid_until = if (user.paid_until >= bank_data_last_updated) && (user.paid_until < Time.now)
          today
        else
          user.paid_until
        end

      { "login" => user.login, "expiry_date" => paid_until.strftime(fmt), "hash" => user.door_hash }
    end

    render json: data
  end

  private

  def require_doorputer_key
    unless params["key"] && ActiveSupport::SecurityUtils.secure_compare(params["key"], Rails.configuration.doorputer_key)
      return render plain: "wrong key", status: 403
    end
  end
end
