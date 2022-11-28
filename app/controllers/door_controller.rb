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
  def doorputer_get_dates
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

  private

  def require_doorputer_key
    unless params["key"] && ActiveSupport::SecurityUtils.secure_compare(params["key"], Rails.configuration.doorputer_key)
      return render plain: "wrong key", status: 403
    end
  end
end
