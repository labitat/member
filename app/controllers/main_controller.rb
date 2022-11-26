class MainController < ApplicationController
  #  layout "user"

  before_action :login_required

  def index
  end

  def payment_info
    @monthly_fee = Value.find_by_name("monthly_fee").value.to_i
  end
end
