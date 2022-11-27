# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_11_27_222341) do
  create_table "door_hashes", force: :cascade do |t|
    t.boolean "verified", default: false, null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "received", null: false
    t.float "amount", null: false
    t.string "comment"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.boolean "will_pay", default: false, null: false
    t.boolean "mailing_list_member", default: false, null: false
    t.date "verified_date"
    t.string "auth_code"
    t.boolean "verified", default: false, null: false
    t.string "login", null: false
    t.string "crypted_password", limit: 40, null: false
    t.string "salt", limit: 40, null: false
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "group", default: "member", null: false
    t.boolean "blocked", default: false, null: false
    t.string "new_email"
    t.boolean "mailing_list", default: true, null: false
    t.text "forgot_password_token"
    t.datetime "forgot_password_expires"
    t.date "paid_until"
    t.string "door_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["login"], name: "index_users_on_login", unique: true
  end

  create_table "values", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
