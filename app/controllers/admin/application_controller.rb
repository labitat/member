class Admin::ApplicationController < ApplicationController
  before_action :admin_required
end
