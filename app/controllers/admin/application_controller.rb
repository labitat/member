require "authenticated_system"

class Admin::ApplicationController < ApplicationController
  include AuthenticatedSystem

  before_action :admin_required
end
