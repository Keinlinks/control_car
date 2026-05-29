require "test_helper"

module AiServices
  class AiServiceTest < ActiveSupport::TestCase
    test "raises until a concrete implementation is provided" do
      service = AiService.new

      error = assert_raises(NotImplementedError) do
        service.generate(prompt: "Summarize this", input: "Some input")
      end

      assert_equal "AiServices::AiService must implement #generate", error.message
    end
  end
end
