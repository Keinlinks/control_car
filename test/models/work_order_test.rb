require "test_helper"

class WorkOrderTest < ActiveSupport::TestCase
  test "defines its fields and supports high priority" do
    work_order = WorkOrder.new(
      license_plate: "ABCD12",
      customer_name: "Jane Doe",
      mileage: 54_321,
      reason_for_entry: "Engine noise",
      priority: :high,
      created_at: Time.current,
      updated_at: Time.current
    )

    assert work_order.valid?
    assert work_order.high?
    assert_respond_to work_order, :created_at
    assert_respond_to work_order, :updated_at
  end

  test "has many images" do
    association = WorkOrder.reflect_on_association(:images)

    assert_not_nil association
    assert_equal :has_many, association.macro
    assert_equal Image, association.klass
  end

  test "has one work order analysis" do
    association = WorkOrder.reflect_on_association(:work_order_analysis)

    assert_not_nil association
    assert_equal :has_one, association.macro
    assert_equal WorkOrderAnalysis, association.klass
  end

  test "inherits from entity record" do
    assert_equal EntityRecord, WorkOrder.superclass
  end
end
