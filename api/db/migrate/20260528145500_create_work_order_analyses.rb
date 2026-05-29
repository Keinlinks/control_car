class CreateWorkOrderAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_analyses do |t|
      t.string :estimated_category, null: false
      t.integer :estimated_priority, null: false
      t.json :possible_failures, null: false, default: []
      t.json :recommended_steps, null: false, default: []
      t.references :work_order, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
