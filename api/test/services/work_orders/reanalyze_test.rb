require "test_helper"

module WorkOrders
  class ReanalyzeTest < ActiveSupport::TestCase
    FakeAiService = Struct.new(:response, :error, keyword_init: true) do
      def generate(prompt:, input: nil, options: {})
        raise error unless error.nil?

        response
      end
    end

    test "creates a new work order analysis for an existing work order" do
      work_order = WorkOrder.create!(
        license_plate: "ABCD12",
        customer_name: "Jane Doe",
        mileage: 54_321,
        reason_for_entry: "Engine noise",
        priority: :high
      )

      result = nil

      assert_difference("WorkOrderAnalysis.count", 1) do
        result = Reanalyze.call(
          work_order_id: work_order.id,
          ai_service: FakeAiService.new(
            response: {
              estimated_category: "engine",
              possible_failures: ["Loose timing component"],
              estimated_priority: "high",
              recommended_steps: ["Run engine diagnostics"]
            }
          )
        )
      end

      assert_equal work_order.id, result.work_order.id
      assert_equal work_order.id, result.work_order_analysis.work_order_id
      assert_equal "engine", result.work_order_analysis.estimated_category
      assert_equal(
        {
          "license_plate" => "ABCD12",
          "customer_name" => "Jane Doe",
          "mileage" => 54_321,
          "reason_for_entry" => "Engine noise",
          "priority" => "high"
        },
        result.work_order_analysis.reload.work_order_snapshot
      )
    end

    test "raises a domain error when analysis generation fails" do
      work_order = WorkOrder.create!(
        license_plate: "ZXCV98",
        customer_name: "John Doe",
        mileage: 12_345,
        reason_for_entry: "Brake check",
        priority: :low
      )

      assert_no_difference("WorkOrderAnalysis.count") do
        error = assert_raises(Reanalyze::Error) do
          Reanalyze.call(
            work_order_id: work_order.id,
            ai_service: FakeAiService.new(error: StandardError.new("AI failure"))
          )
        end

        assert_equal "work_order analysis could not be generated", error.message
      end
    end
  end
end
