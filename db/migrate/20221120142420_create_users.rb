class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string "email", unique: true, null: false
      t.string "name", null: false
      t.string "phone", null: false
      t.boolean "will_pay", :default => false, null: false
      t.boolean "mailing_list_member", :default => false, null: false
      t.date "verified_date"
      t.string "auth_code"
      t.boolean "verified", :default => false, null: false
      t.string "login", null: false
      t.string "crypted_password", :limit => 40, null: false
      t.string "salt", :limit => 40, null: false
      t.string "remember_token"
      t.datetime "remember_token_expires_at"
      t.string "group", :default => "member", null: false
      t.boolean "blocked", :default => false, null: false
      t.string "new_email"
      t.boolean "mailing_list", :default => true, null: false
      t.text "forgot_password_token"
      t.datetime "forgot_password_expires"
      t.date "paid_until"
      t.string "door_hash"
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :login, unique: true
  end
end
