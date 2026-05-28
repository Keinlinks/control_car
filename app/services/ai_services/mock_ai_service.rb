module AiServices
  class MockAiService < AiService
    def generate(prompt:, input: nil, options: {})
      reason_for_entry = input.to_s.downcase

      {
        estimated_category: estimated_category_for(reason_for_entry),
        possible_failures: possible_failures_for(reason_for_entry),
        estimated_priority: estimated_priority_for(reason_for_entry),
        recommended_steps: recommended_steps_for(reason_for_entry)
      }
    end

    private

    def estimated_category_for(reason_for_entry)
      return "brakes" if reason_for_entry.include?("brake")
      return "engine" if reason_for_entry.include?("engine")

      "general_inspection"
    end

    def possible_failures_for(reason_for_entry)
      return ["Worn brake pads", "Brake fluid leak"] if reason_for_entry.include?("brake")
      return ["Loose timing component", "Oil circulation issue"] if reason_for_entry.include?("engine")

      ["Pending physical inspection"]
    end

    def estimated_priority_for(reason_for_entry)
      return "high" if reason_for_entry.include?("engine") || reason_for_entry.include?("brake")

      "low"
    end

    def recommended_steps_for(reason_for_entry)
      return ["Inspect brake system", "Verify brake fluid level"] if reason_for_entry.include?("brake")
      return ["Run engine diagnostics", "Inspect lubrication system"] if reason_for_entry.include?("engine")

      ["Perform general inspection"]
    end
  end
end
