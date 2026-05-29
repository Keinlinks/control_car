class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders, if_not_exists: true do |t|
      t.string :license_plate
      t.string :customer_name
      t.integer :mileage
      t.string :reason_for_entry
      t.integer :priority
      t.timestamps
    end
  end
end
