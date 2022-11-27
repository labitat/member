class CreateDoorHashes < ActiveRecord::Migration[7.0]
  def change
    create_table :door_hashes do |t|
      t.boolean "verified", :default => false, null: false
      t.string "value", null: false
      t.timestamps
    end
  end
end
