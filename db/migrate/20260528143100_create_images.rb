class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images, if_not_exists: true do |t|
      t.string :storage_path, null: false
      t.references :work_order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
