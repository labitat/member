require "test_helper"

class RegistrationControllerTest < ActionDispatch::IntegrationTest
  test "should allow registration" do
    visit signup_url
    within "#registration" do
      fill_in "user_email", with: "hello@there.com"
      fill_in "user_login", with: "hey"
      fill_in "user_name", with: "heythere"
      fill_in "user_password", with: "pass123"
      fill_in "user_password_confirmation", with: "pass123"
    end
    click_button "Sign up"
    assert_content "Signup is almost complete"
  end

  test "should not allow registration without matching passwords" do
    visit signup_url
    within "#registration" do
      fill_in "user_email", with: "hello@there.com"
      fill_in "user_login", with: "hey"
      fill_in "user_name", with: "heythere"
      fill_in "user_password", with: "pass123"
      fill_in "user_password_confirmation", with: "pass345"
    end
    click_button "Sign up"
    assert_content "password did not match"
  end
end
