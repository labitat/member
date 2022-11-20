require "authenticated_system"

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
end
