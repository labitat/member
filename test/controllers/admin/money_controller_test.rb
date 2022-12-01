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
    User.create!(password: "pass123", login: "something", email: "something@there.com", password_confirmation: "pass123", name: "something", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")
    User.create!(password: "pass123", login: "something2", email: "something2@there.com", password_confirmation: "pass123", name: "something2", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")

    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    login(@user)
    visit admin_money_upload_path
    fill_in "bankdata", with: %|01-04-2020;"something";1500\n01-06-2020;"something2";1700\n01-10-2020;"something3";100\n|
    click_button "Upload"
    assert_content "The system will attempt to auto-detect"
    assert_select "payment[0][user_id]", selected: "something"
    assert_select "payment[1][user_id]", selected: "something2"
    refute_content "something3"
    click_button "Approve!"
  end

  test "stats" do
    User.create!(password: "pass123", login: "something", email: "something@there.com", password_confirmation: "pass123", name: "something", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")
    User.create!(password: "pass123", login: "something2", email: "something2@there.com", password_confirmation: "pass123", name: "something2", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey")

    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    login(@user)
    visit admin_money_stats_path
    assert_content "Paying: 0"
  end

  test "creating payments" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    login(@user)
    visit admin_money_new_path
    fill_in "payment_amount", with: "12300"
    fill_in "payment_received", with: "2020-02-08"
    select @user.login, from: "payment_user_id"
    fill_in "payment_source", with: "somesource"
    click_button "Save"
    assert_content "Payment created!"
    payment = @user.payments.first
    assert_equal 12300, payment.amount
    assert_equal @user.id, payment.user_id
    assert_equal "somesource", payment.source
    assert_equal Date.new(2020, 2, 8), payment.received
  end

  test "updating payments" do
    @user = User.create!(password: "pass123", login: "hey", email: "hey@there.com", password_confirmation: "pass123", name: "hey", phone: "12341234", verified: true, paid_until: Time.now - 1.month, door_hash: "heyhey", group: "admin")
    @user.payments.create!(received: "2020-03-14", amount: 123, comment: "hey guys", source: "a source")
    login(@user)
    visit admin_money_edit_path(id: @user.payments.first.id)
    # puts page.body

    fill_in "payment_amount", with: "12300"
    fill_in "payment_received", with: "2020-04-18"
    fill_in "payment_source", with: "b source"
    assert_content "hey guys"
    click_button "Update"
    assert_content "Payment updated!"
    payment = @user.payments.first
    assert_equal 1, @user.payments.count
    assert_equal 12300, payment.amount
    assert_equal @user.id, payment.user_id
    assert_equal "b source", payment.source
    assert_equal Date.new(2020, 4, 18), payment.received
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
