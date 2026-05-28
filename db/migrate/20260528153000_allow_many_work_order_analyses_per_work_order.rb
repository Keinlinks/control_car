class AllowManyWorkOrderAnalysesPerWorkOrder < ActiveRecord::Migration[8.1]
  def change
    remove_index :work_order_analyses, :work_order_id
    add_index :work_order_analyses, :work_order_id
  end
end
