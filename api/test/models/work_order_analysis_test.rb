require "test_helper"

class WorkOrderAnalysisTest < ActiveSupport::TestCase
  test "belongs to a work order" do
    association = WorkOrderAnalysis.reflect_on_association(:work_order)

    assert_not_nil association
    assert_equal :belongs_to, association.macro
    assert_equal WorkOrder, association.klass
  end

  test "supports low and high estimated priority" do
    analysis = WorkOrderAnalysis.new(
      estimated_category: "mechanical",
      estimated_priority: :high,
      possible_failures: [ "Worn brake pads", "Fluid leak" ],
      recommended_steps: [ "Inspect brakes", "Check hydraulic lines" ],
      work_order: valid_work_order
    )

    assert analysis.valid?
    assert analysis.high?
  end

  test "requires possible_failures to contain only strings" do
    analysis = WorkOrderAnalysis.new(
      estimated_category: "electrical",
      estimated_priority: :low,
      possible_failures: [ "Battery issue", 123 ],
      recommended_steps: [ "Run diagnostics" ],
      work_order: valid_work_order
    )

    assert_not analysis.valid?
    assert_includes analysis.errors[:possible_failures], "must contain only strings"
  end

  test "requires recommended_steps to be an array of strings" do
    analysis = WorkOrderAnalysis.new(
      estimated_category: "electrical",
      estimated_priority: :low,
      possible_failures: [ "Battery issue" ],
      recommended_steps: "Run diagnostics",
      work_order: valid_work_order
    )

    assert_not analysis.valid?
    assert_includes analysis.errors[:recommended_steps], "must be an array"
  end

  test "requires work_order_snapshot to be a hash" do
    analysis = WorkOrderAnalysis.new(
      estimated_category: "electrical",
      estimated_priority: :low,
      possible_failures: ["Battery issue"],
      recommended_steps: ["Run diagnostics"],
      work_order_snapshot: "not-a-hash",
      work_order: valid_work_order
    )

    assert_not analysis.valid?
    assert_includes analysis.errors[:work_order_snapshot], "must be a hash"
  end

  test "inherits from entity record" do
    assert_equal EntityRecord, WorkOrderAnalysis.superclass
  end

  private

  def valid_work_order
    WorkOrder.new(
      license_plate: "ABCD12",
      customer_name: "Jane Doe",
      mileage: 54_321,
      reason_for_entry: "Engine noise",
      priority: :high
    )
  end
end
