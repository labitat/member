require "test_helper"

class UserControllerTest < ActionDispatch::IntegrationTest
  test "shouldn't allow users to view anything without logging in" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    visit user_info_path
    assert_selector "#login"
  end

  test "should allow logged in members to view their payment status if never paid" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    login @user
    visit user_info_path
    assert_content "According to our records you have never paid"
  end

  test "should allow logged in members to view their payment status if paid" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now + 1.month)
    login @user
    visit user_info_path
    assert_content "will expire on"
  end

  test "should allow logged in members to view their payment status if paid but expired" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    login @user
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

  test "should say if there are no unclaimed hashes" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    login(@user)
    visit user_hashes_url
    assert_content "No unclaimed card+pin info available"
  end

  test "should allow claiming a hash" do
    DoorHash.create!(value: "heyhey", verified: true)
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month)
    login(@user)
    visit user_hashes_url
    click_link "claim"
    assert_content "Your card+pin info is currently set"
  end

  test "should allow clearing a hash" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")
    login(@user)
    visit user_info_path
    assert_content "Your card+pin info is currently set"
    click_link "clear your door-hash"
    assert_content "will need to load your card+pin data into the system"
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
