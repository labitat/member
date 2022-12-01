class CreateValues < ActiveRecord::Migration[7.0]
  def change
    create_table :values do |t|
      t.string "name"
      t.string "value"
      t.timestamps
      t.index :name, unique: true
    end
  end
end
