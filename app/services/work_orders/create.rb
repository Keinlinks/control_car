module WorkOrders
  class Create
    Result = Struct.new(:work_order, :work_order_analysis, keyword_init: true)
    ANALYSIS_PROMPT = <<~PROMPT.freeze
      Analyze the work order reason for entry and return a structure compatible with WorkOrderAnalysis.
      The response must include:
      - estimated_category: string
      - possible_failures: array of strings
      - estimated_priority: low or high
      - recommended_steps: array of strings
    PROMPT

    def self.call(work_order_attributes:, image_files:, image_storage:, ai_service:)
      new(
        work_order_attributes:,
        image_files:,
        image_storage:,
        ai_service:
      ).call
    end

    def initialize(work_order_attributes:, image_files:, image_storage:, ai_service:)
      @work_order_attributes = work_order_attributes
      @image_files = Array(image_files).compact_blank
      @image_storage = image_storage
      @ai_service = ai_service
      @stored_paths = []
    end

    def call
      work_order = nil

      ActiveRecord::Base.transaction do
        work_order = WorkOrder.create!(@work_order_attributes)
        persist_images!(work_order)
      end

      Result.new(
        work_order:,
        work_order_analysis: persist_analysis(work_order)
      )
    rescue StandardError
      enqueue_orphaned_images_cleanup
      raise
    end

    private

    def persist_images!(work_order)
      @image_files.each do |uploaded_file|
        storage_path = @image_storage.store(
          uploaded_file:,
          work_order_id: work_order.id
        )
        @stored_paths << storage_path

        work_order.images.create!(storage_path:)
      end
    end

    def enqueue_orphaned_images_cleanup
      storage_paths = @stored_paths.compact_blank
      return if storage_paths.empty?

      DeleteOrphanedImagesJob.perform_later(@image_storage.class.name, storage_paths)
    end

    def persist_analysis(work_order)
      analysis_attributes = @ai_service.generate(
        prompt: ANALYSIS_PROMPT,
        input: work_order.reason_for_entry
      )

      normalized_attributes = normalize_analysis_attributes(analysis_attributes)

      work_order.work_order_analyses.create!(normalized_attributes)
    rescue StandardError
      nil
    end

    def normalize_analysis_attributes(attributes)
      attributes = attributes.to_h.deep_symbolize_keys

      {
        estimated_category: attributes[:estimated_category],
        possible_failures: attributes[:possible_failures],
        estimated_priority: attributes[:estimated_priority],
        recommended_steps: attributes[:recommended_steps]
      }
    end
  end
end
