require "test_helper"

class WorkOrdersIndexFlowTest < ActionDispatch::IntegrationTest
  test "returns paginated work orders ordered by created_at desc without images" do
    older_work_order = WorkOrder.create!(
      license_plate: "OLD123",
      customer_name: "Older Customer",
      mileage: 10_000,
      reason_for_entry: "Older issue",
      priority: :low,
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )

    middle_work_order = WorkOrder.create!(
      license_plate: "MID123",
      customer_name: "Middle Customer",
      mileage: 20_000,
      reason_for_entry: "Middle issue",
      priority: :high,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    newer_work_order = WorkOrder.create!(
      license_plate: "NEW123",
      customer_name: "Newer Customer",
      mileage: 30_000,
      reason_for_entry: "Newer issue",
      priority: :high,
      created_at: Time.current,
      updated_at: Time.current
    )

    newer_work_order.images.create!(storage_path: "work_orders/#{newer_work_order.id}/sample.jpg")

    get work_orders_path, params: { page: 1, pageSize: 2 }

    assert_response :ok

    response_body = JSON.parse(response.body)

    assert_equal 1, response_body["page"]
    assert_equal 2, response_body["pageSize"]
    assert_equal 3, response_body["total"]
    assert_equal [newer_work_order.id, middle_work_order.id], response_body["items"].map { |item| item["id"] }
    assert_equal "NEW123", response_body["items"][0]["license_plate"]
    assert_equal "MID123", response_body["items"][1]["license_plate"]
    assert_not response_body["items"][0].key?("images")
    assert_not_includes response_body["items"].map { |item| item["id"] }, older_work_order.id
  end

  test "returns validation errors for invalid pagination values" do
    get work_orders_path, params: { page: 0, pageSize: 0 }

    assert_response :unprocessable_content
    assert_equal ["page and pageSize must be greater than 0"], JSON.parse(response.body)["errors"]
  end

  test "returns validation errors when pageSize exceeds the limit" do
    get work_orders_path, params: { page: 1, pageSize: 101 }

    assert_response :unprocessable_content
    assert_equal ["pageSize must be less than or equal to 100"], JSON.parse(response.body)["errors"]
  end
end
