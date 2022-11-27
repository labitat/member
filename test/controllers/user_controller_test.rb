require "test_helper"

class MainControllerTest < ActionDispatch::IntegrationTest
  test "shouldn't allow users to view anything without logging in" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    visit user_info_path
    assert_selector "#login"
  end

  test "should allow logged in members to view their payment status if never paid" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    visit user_info_path
    assert_content "According to our records you have never paid"
  end

  test "should allow logged in members to view their payment status if paid" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now + 1.month)
    # @user.payments.create!(received: Time.now - 3.days, amount: 500, user_id: @user.id)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    visit user_info_path
    assert_content "will expire on"
  end

  test "should allow logged in members to view their payment status if paid but expired" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    # @user.payments.create!(received: Time.now - 3.days, amount: 500, user_id: @user.id)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    visit user_info_path
    assert_content "expired on"
  end

  test "should not send radius hashes without a key" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    visit radius_hashes_url
    assert_content "wrong key"
  end

  test "should send radius hashes with a key" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    visit radius_hashes_url(key: "")
    assert_content "ASSHA-Password := \"#{@user.crypted_password}#{@user.salt}\""
  end
end
