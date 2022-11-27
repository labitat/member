class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.integer "user_id", null: false
      t.date "received", null: false
      t.float "amount", null: false
      t.string "comment"
      t.string "source"

      t.timestamps
    end
  end
end
