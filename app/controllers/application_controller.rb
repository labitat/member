require "authenticated_system"

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  before_action :require_https
  before_action :attempt_set_current_user

  def require_https
    !Rails.env.production? || request.ssl?
  end
end
