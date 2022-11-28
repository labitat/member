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
end
