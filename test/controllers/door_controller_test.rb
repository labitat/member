require "test_helper"

class DoorControllerTest < ActionDispatch::IntegrationTest
  test "should reject without a key" do
    visit new_door_hash_path
    assert_content "wrong key"
  end

  test "should accept a key but needs a hash" do
    visit new_door_hash_path(key: "")
    assert_content "no hash received"
  end

  test "should accept a key & a hash" do
    visit new_door_hash_path(key: "", hash: "somehash")
    assert_content "new hash created"
  end

  test "should verify a hash" do
    visit new_door_hash_path(key: "", hash: "somehash")
    assert_content "new hash created"
    visit new_door_hash_path(key: "", hash: "somehash")
    assert_content "hash verified"
  end

  test "shouldn't verify a hash if its too old" do
    visit new_door_hash_path(key: "", hash: "somehash")
    assert_content "new hash created"
    travel_to Time.now + (Rails.configuration.doorputer_verify_max_delay + 10).seconds
    visit new_door_hash_path(key: "", hash: "somehash")
    assert_content "timeout passed, you'll have to start over"
  end

  test "list door hashes" do
    freeze_time do
      Value.create!(name: "bank_data_last_updated", value: "2021-05-25")
      User.create!(email: "hello1@there.com", password: "hello", password_confirmation: "hello", login: "hello1", name: "hello there", phone: "", door_hash: "hello1")
      User.create!(email: "hello2@there.com", password: "hello", password_confirmation: "hello", login: "hello2", name: "hello there", phone: "", paid_until: "2022-06-24")
      User.create!(email: "hello3@there.com", password: "hello", password_confirmation: "hello", login: "hello3", name: "hello there", phone: "", paid_until: "2022-06-24", door_hash: "hello3")
      User.create!(email: "hello4@there.com", password: "hello", password_confirmation: "hello", login: "hello4", name: "hello there", phone: "", paid_until: "2020-06-24", door_hash: "hello4")
      visit door_hash_list_path(key: "")
      assert_equal [{ "login" => "hello3", "expiry_date" => Time.now.strftime("%Y-%m-%d"), "hash" => "hello3" }, { "login" => "hello4", "expiry_date" => "2020-06-24", "hash" => "hello4" }], JSON.parse(page.body)
    end
  end
end
