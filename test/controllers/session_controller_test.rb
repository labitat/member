require "test_helper"

class MainControllerTest < ActionDispatch::IntegrationTest
  test "should allow verified users to login" do
    User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    assert_content "Login successful"
  end

  test "should prevent unverified users to login" do
    User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: false)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    assert_content "You must verify your email"
  end

  test "should prevent login without a correct password" do
    User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: false)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass321"
    end
    click_button "Log in"
    assert_content "Login error"
  end

  test "should prevent login without a correct username" do
    User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: false)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey123"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    assert_content "Login error"
  end

  test "should allow logout" do
    User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true)
    visit new_session_url
    within "#session" do
      fill_in "login", with: "hey"
      fill_in "password", with: "pass123"
    end
    click_button "Log in"
    assert_content "Login successful"
    click_link "log out"
    assert_selector "#session"
  end
end
