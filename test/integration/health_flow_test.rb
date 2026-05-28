require "test_helper"

class HealthFlowTest < ActionDispatch::IntegrationTest
  test "returns ok status for api health check" do
    get "/health"

    assert_response :ok
    assert_equal({ "status" => "ok" }, JSON.parse(response.body))
  end
end
