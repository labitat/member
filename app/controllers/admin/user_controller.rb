class Admin::UserController < ApplicationController
  def list
    @filter = params[:filter] || "all"

    case @filter
    when "all"
      @users = User.all
    when "paying"
      render :text => "not implemented"
      return
    when "marked_as_paying"
      @users = User.marked_as_paying
    when "verified"
      @users = User.verified
    when "unverified"
      @users = User.unverified
    when "blocked"
      @users = User.blocked
    end

    @filter.capitalize!

    @num_verified_users = User.count(:conditions => "verified = 1 AND blocked = 0")
  end
end
