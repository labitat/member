require "authenticated_system"

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  before_action :attempt_set_current_user
end
