class Admin::ApplicationController < ApplicationController
  before_action :admin_required

  def admin_required
    unless current_user && current_user.is_admin?
      render plain: 401
    end
  end
end
