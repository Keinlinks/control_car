require "test_helper"

class WorkOrdersFlowTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  test "creates a work order with multipart images" do
    assert_difference("WorkOrder.count", 1) do
      assert_difference("Image.count", 2) do
        assert_difference("WorkOrderAnalysis.count", 1) do
          post work_orders_path,
               params: {
                 work_order: {
                   license_plate: "ABCD12",
                   customer_name: "Jane Doe",
                   mileage: 54_321,
                   reason_for_entry: "Engine noise",
                   priority: "high"
                 },
                 images: [
                   fixture_file_upload("sample-upload.jpg", "image/jpeg"),
                   fixture_file_upload("sample-upload.jpg", "image/jpeg")
                 ]
               }
        end
      end
    end

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal "ABCD12", response_body["workOrder"]["license_plate"]
    assert_equal "high", response_body["workOrder"]["priority"]
    assert_equal 2, response_body["workOrder"]["images"].size
    assert_equal "engine", response_body["workOrderAnalysis"]["estimated_category"]
    assert_equal "high", response_body["workOrderAnalysis"]["estimated_priority"]
  end

  test "creates a work order without images" do
    assert_difference("WorkOrder.count", 1) do
      assert_difference("WorkOrderAnalysis.count", 1) do
        assert_no_difference("Image.count") do
          post work_orders_path,
               params: {
                 work_order: {
                   license_plate: "ZXCV98",
                   customer_name: "John Doe",
                   mileage: 12_345,
                   reason_for_entry: "Brake check",
                   priority: "low"
                 }
               }
        end
      end
    end

    assert_response :created

    response_body = JSON.parse(response.body)

    assert_equal [], response_body["workOrder"]["images"]
    assert_equal "brakes", response_body["workOrderAnalysis"]["estimated_category"]
  end

  test "returns validation errors when the payload is invalid" do
    assert_no_difference("WorkOrder.count") do
      post work_orders_path,
           params: {
             work_order: {
               license_plate: "",
               customer_name: "Jane Doe",
               mileage: -1,
               reason_for_entry: "",
               priority: ""
             },
             images: [ "not-a-file" ]
           }
    end

    assert_response :unprocessable_content

    response_body = JSON.parse(response.body)

    assert_includes response_body["errors"], "License plate can't be blank"
    assert_includes response_body["errors"], "Mileage must be greater than or equal to 0"
    assert_includes response_body["errors"], "Images must be uploaded files"
  end
end
