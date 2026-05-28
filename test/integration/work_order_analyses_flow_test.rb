require "test_helper"

class WorkOrderAnalysesFlowTest < ActionDispatch::IntegrationTest
  test "creates a new analysis for an existing work order" do
    work_order = WorkOrder.create!(
      license_plate: "ABCD12",
      customer_name: "Jane Doe",
      mileage: 54_321,
      reason_for_entry: "Engine noise",
      priority: :high
    )

    work_order.work_order_analyses.create!(
      estimated_category: "older",
      estimated_priority: :low,
      possible_failures: ["Older issue"],
      recommended_steps: ["Older step"]
    )

    assert_difference("WorkOrderAnalysis.count", 1) do
      post work_order_work_order_analyses_path(work_order)
    end

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal work_order.id, response_body["workOrderAnalysis"]["work_order_id"]
    assert_equal "engine", response_body["workOrderAnalysis"]["estimated_category"]
    assert_equal 2, work_order.work_order_analyses.count
  end

  test "returns paginated analyses ordered by created_at desc" do
    work_order = WorkOrder.create!(
      license_plate: "ABCD12",
      customer_name: "Jane Doe",
      mileage: 54_321,
      reason_for_entry: "Engine noise",
      priority: :high
    )

    older_analysis = work_order.work_order_analyses.create!(
      estimated_category: "older",
      estimated_priority: :low,
      possible_failures: ["Older issue"],
      recommended_steps: ["Older step"],
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )

    middle_analysis = work_order.work_order_analyses.create!(
      estimated_category: "middle",
      estimated_priority: :high,
      possible_failures: ["Middle issue"],
      recommended_steps: ["Middle step"],
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    newer_analysis = work_order.work_order_analyses.create!(
      estimated_category: "newer",
      estimated_priority: :high,
      possible_failures: ["New issue"],
      recommended_steps: ["New step"],
      created_at: Time.current,
      updated_at: Time.current
    )

    get work_order_work_order_analyses_path(work_order), params: { page: 1, pageSize: 2 }

    assert_response :ok

    response_body = JSON.parse(response.body)

    assert_equal 1, response_body["page"]
    assert_equal 2, response_body["pageSize"]
    assert_equal 3, response_body["total"]
    assert_equal [newer_analysis.id, middle_analysis.id], response_body["items"].map { |item| item["id"] }
    assert_equal "newer", response_body["items"][0]["estimated_category"]
    assert_equal "middle", response_body["items"][1]["estimated_category"]
    assert_not_includes response_body["items"].map { |item| item["id"] }, older_analysis.id
  end

  test "returns not found when the work order does not exist" do
    get "/work_orders/999999/work_order_analyses", params: { page: 1, pageSize: 10 }

    assert_response :not_found
    assert_equal ["work_order not found"], JSON.parse(response.body)["errors"]
  end

  test "returns an error when analysis generation fails" do
    work_order = WorkOrder.create!(
      license_plate: "ZXCV98",
      customer_name: "John Doe",
      mileage: 12_345,
      reason_for_entry: "Brake check",
      priority: :low
    )

    failing_ai_service = Object.new
    failing_ai_service.define_singleton_method(:generate) do |prompt:, input: nil, options: {}|
      raise StandardError, "AI failure"
    end

    original_new = AiServices::MockAiService.method(:new)
    AiServices::MockAiService.define_singleton_method(:new) { failing_ai_service }

    begin
      assert_no_difference("WorkOrderAnalysis.count") do
        post work_order_work_order_analyses_path(work_order)
      end
    ensure
      AiServices::MockAiService.define_singleton_method(:new, original_new)
    end

    assert_response :internal_server_error
    assert_equal ["work_order analysis could not be generated"], JSON.parse(response.body)["errors"]
  end

  test "returns validation errors for invalid pagination values" do
    work_order = WorkOrder.create!(
      license_plate: "ZXCV98",
      customer_name: "John Doe",
      mileage: 12_345,
      reason_for_entry: "Brake check",
      priority: :low
    )

    get work_order_work_order_analyses_path(work_order), params: { page: 0, pageSize: 0 }

    assert_response :unprocessable_content
    assert_equal ["page and pageSize must be greater than 0"], JSON.parse(response.body)["errors"]
  end

  test "returns validation errors when pageSize exceeds the limit" do
    work_order = WorkOrder.create!(
      license_plate: "ZXCV98",
      customer_name: "John Doe",
      mileage: 12_345,
      reason_for_entry: "Brake check",
      priority: :low
    )

    get work_order_work_order_analyses_path(work_order), params: { page: 1, pageSize: 101 }

    assert_response :unprocessable_content
    assert_equal ["pageSize must be less than or equal to 100"], JSON.parse(response.body)["errors"]
  end
end
