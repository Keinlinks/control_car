class AddWorkOrderSnapshotToWorkOrderAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_analyses, :work_order_snapshot, :json, null: false, default: {}
  end
end
