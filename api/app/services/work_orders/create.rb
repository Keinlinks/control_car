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
      Rails.logger.info("work_order.create started")
      Rails.logger.debug(
        "work_order.create payload license_plate=#{@work_order_attributes[:license_plate].inspect} " \
        "priority=#{@work_order_attributes[:priority].inspect} image_count=#{@image_files.size}"
      )

      work_order = nil

      ActiveRecord::Base.transaction do
        work_order = WorkOrder.create!(@work_order_attributes)
        persist_images!(work_order)
      end

      work_order_analysis = persist_analysis(work_order)

      Rails.logger.info(
        "work_order.create completed work_order_id=#{work_order.id} " \
        "analysis_created=#{!work_order_analysis.nil?} image_count=#{work_order.images.size}"
      )

      Result.new(
        work_order:,
        work_order_analysis:
      )
    rescue StandardError => error
      Rails.logger.warn(
        "work_order.create failed error_class=#{error.class.name} message=#{error.message.inspect}"
      )
      Rails.logger.debug(error.backtrace.join("\n")) if error.backtrace.present?
      enqueue_orphaned_images_cleanup
      raise
    end

    private

    def persist_images!(work_order)
      @image_files.each do |uploaded_file|
        Rails.logger.debug(
          "work_order.create storing image work_order_id=#{work_order.id} " \
          "filename=#{uploaded_file.original_filename.inspect}"
        )
        storage_path = @image_storage.store(
          uploaded_file:,
          work_order_id: work_order.id
        )
        @stored_paths << storage_path

        work_order.images.create!(storage_path:)
        Rails.logger.debug(
          "work_order.create stored image work_order_id=#{work_order.id} storage_path=#{storage_path.inspect}"
        )
      end
    end

    def enqueue_orphaned_images_cleanup
      storage_paths = @stored_paths.compact_blank
      return if storage_paths.empty?

      Rails.logger.info(
        "work_order.create enqueueing orphaned image cleanup count=#{storage_paths.size}"
      )
      DeleteOrphanedImagesJob.perform_later(@image_storage.class.name, storage_paths)
    end

    def persist_analysis(work_order)
      Rails.logger.info("work_order.create generating analysis work_order_id=#{work_order.id}")
      analysis_attributes = @ai_service.generate(
        prompt: ANALYSIS_PROMPT,
        input: work_order.reason_for_entry
      )
      Rails.logger.debug(
        "work_order.create analysis response work_order_id=#{work_order.id} " \
        "keys=#{analysis_attributes.to_h.keys.map(&:to_s).sort.join(",")}"
      )

      normalized_attributes = normalize_analysis_attributes(analysis_attributes, work_order)

      analysis = work_order.work_order_analyses.create!(normalized_attributes)
      Rails.logger.info(
        "work_order.create analysis persisted work_order_id=#{work_order.id} analysis_id=#{analysis.id}"
      )
      analysis
    rescue StandardError => error
      Rails.logger.info(
        "work_order.create analysis skipped work_order_id=#{work_order.id} " \
        "error_class=#{error.class.name} message=#{error.message.inspect}"
      )
      Rails.logger.debug(error.backtrace.join("\n")) if error.backtrace.present?
      nil
    end

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
