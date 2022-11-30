require "test_helper"

class Admin::MoneyControllerTest < ActionDispatch::IntegrationTest
  test "should reject if you're not logged in" do
    visit admin_money_url
    assert_content "401"
  end

  test "should reject unless you're an admin" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")
    login(@user)
    visit admin_money_url
    assert_content "401"
  end

  test "should show money#index if you're an admin" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    login(@user)
    visit admin_money_url
    assert_content "Money handling"
  end

  test "upload and confirm bank data" do
    @user = User.create!(password: "pass123", login: "something", email: "something@there.com", password_confirmation: "pass123", name: "something", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")
    @user = User.create!(password: "pass123", login: "something2", email: "something2@there.com", password_confirmation: "pass123", name: "something2", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")

    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    login(@user)
    visit admin_money_upload_path
    fill_in "bankdata", with: %|01-04-2020;"something";1500\n01-06-2020;"something2";1700\n|
    click_button "Upload"
    assert_content "The system will attempt to auto-detect"
    assert_select "payment[0][user_id]", selected: "something"
    assert_select "payment[1][user_id]", selected: "something2"
    click_button "Approve!"
  end

  private

  def login(user)
    visit new_session_url
    within "#session" do
      fill_in "login", with: user.login
      fill_in "password", with: user.password
    end
    click_button "Log in"
  end
end
