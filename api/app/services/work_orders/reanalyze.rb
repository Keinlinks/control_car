module WorkOrders
  class Reanalyze
    class Error < StandardError; end

    Result = Struct.new(:work_order, :work_order_analysis, keyword_init: true)
    ANALYSIS_PROMPT = <<~PROMPT.freeze
      Analyze the work order reason for entry and return a structure compatible with WorkOrderAnalysis.
      The response must include:
      - estimated_category: string
      - possible_failures: array of strings
      - estimated_priority: low or high
      - recommended_steps: array of strings
    PROMPT

    def self.call(work_order_id:, ai_service:)
      new(work_order_id:, ai_service:).call
    end

    def initialize(work_order_id:, ai_service:)
      @work_order_id = work_order_id
      @ai_service = ai_service
    end

    def call
      Rails.logger.info("work_order.reanalyze started work_order_id=#{@work_order_id}")
      work_order = WorkOrder.find(@work_order_id)
      Rails.logger.debug(
        "work_order.reanalyze payload work_order_id=#{work_order.id} " \
        "license_plate=#{work_order.license_plate.inspect} priority=#{work_order.priority.inspect}"
      )

      analysis_attributes = @ai_service.generate(
        prompt: ANALYSIS_PROMPT,
        input: work_order.reason_for_entry
      )
      Rails.logger.debug(
        "work_order.reanalyze analysis response work_order_id=#{work_order.id} " \
        "keys=#{analysis_attributes.to_h.keys.map(&:to_s).sort.join(",")}"
      )

      work_order_analysis = work_order.work_order_analyses.create!(normalize_analysis_attributes(analysis_attributes, work_order))
      Rails.logger.info(
        "work_order.reanalyze completed work_order_id=#{work_order.id} analysis_id=#{work_order_analysis.id}"
      )

      Result.new(work_order:, work_order_analysis:)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("work_order.reanalyze failed work_order_id=#{@work_order_id} error=not_found")
      raise
    rescue StandardError => error
      Rails.logger.warn(
        "work_order.reanalyze failed work_order_id=#{@work_order_id} " \
        "error_class=#{error.class.name} message=#{error.message.inspect}"
      )
      Rails.logger.debug(error.backtrace.join("\n")) if error.backtrace.present?
      raise Error, "work_order analysis could not be generated"
    end

    private

    def normalize_analysis_attributes(attributes, work_order)
      attributes = attributes.to_h.deep_symbolize_keys

      {
        estimated_category: attributes[:estimated_category],
        possible_failures: attributes[:possible_failures],
        estimated_priority: attributes[:estimated_priority],
        recommended_steps: attributes[:recommended_steps],
        work_order_snapshot: work_order_snapshot(work_order)
      }
    end

    def work_order_snapshot(work_order)
      {
        license_plate: work_order.license_plate,
        customer_name: work_order.customer_name,
        mileage: work_order.mileage,
        reason_for_entry: work_order.reason_for_entry,
        priority: work_order.priority
      }
    end
  end
end
