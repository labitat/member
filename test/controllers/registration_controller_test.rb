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

  test "should look like its resetting a password even if there is no user" do
    visit forgot_password_url
    within "#forgot_password" do
      fill_in "email", with: "hello@there.com"
    end
    click_button "Do it"
    assert_content "sent by email"
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  test "should reset a password of a non-verified user" do
    user = User.create!(email: "hello@there.com", password: "hello", password_confirmation: "hello", login: "hello", name: "hello there", phone: "")
    visit forgot_password_url
    within "#forgot_password" do
      fill_in "email", with: "hello@there.com"
    end
    click_button "Do it"
    assert_content "sent by email"
    mail = ActionMailer::Base.deliveries.last
    link = mail.body.to_s[/(\/change_password.*?)"/, 1]
    visit link
    within "#change_password" do
      fill_in "password", with: "new password"
      fill_in "password_confirmation", with: "new password"
    end
    click_button "Change password"
    assert_content "password has been updated"
    assert_not_nil User.authenticate("hello", "new password")
  end

  test "should reset a password of a verified user" do
    user = User.create!(email: "hello@there.com", password: "hello", password_confirmation: "hello", login: "hello", name: "hello there", phone: "", verified: true)
    visit forgot_password_url
    within "#forgot_password" do
      fill_in "email", with: "hello@there.com"
    end
    click_button "Do it"
    assert_content "sent by email"
    mail = ActionMailer::Base.deliveries.last
    link = mail.body.to_s[/(\/change_password.*?)"/, 1]
    visit link
    within "#change_password" do
      fill_in "password", with: "new password"
      fill_in "password_confirmation", with: "new password"
    end
    click_button "Change password"
    assert_content "password has been updated"
    assert_not_nil User.authenticate("hello", "new password")
  end
end
