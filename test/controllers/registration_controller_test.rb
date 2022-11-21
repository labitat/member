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

    mail = ActionMailer::Base.deliveries.last
    link = mail.body.to_s[/(\/signup\/verify\?code=.*?)"/, 1]
    visit link
    within "#verify" do
      fill_in "password", with: "pass123"
    end
    User.any_instance.stubs(:mailman_register_all).returns(true)
    User.any_instance.stubs(:mediawiki_register_account).returns(true)
    User.any_instance.stubs(:mediawiki_user_exists?).returns(true)
    click_button "Verify"
    assert_content "Account verification successful"
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
