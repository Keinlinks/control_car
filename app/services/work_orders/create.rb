module WorkOrders
  class Create
    def self.call(work_order_attributes:, image_files:, image_storage:)
      new(
        work_order_attributes:,
        image_files:,
        image_storage:
      ).call
    end

    def initialize(work_order_attributes:, image_files:, image_storage:)
      @work_order_attributes = work_order_attributes
      @image_files = Array(image_files).compact_blank
      @image_storage = image_storage
    end

    def call
      work_order = nil

      ActiveRecord::Base.transaction do
        work_order = WorkOrder.create!(@work_order_attributes)
        persist_images!(work_order)
      end

      work_order
    end

    private

    def persist_images!(work_order)
      @image_files.each do |uploaded_file|
        storage_path = @image_storage.store(
          uploaded_file:,
          work_order_id: work_order.id
        )

        work_order.images.create!(storage_path:)
      end
    end
  end
end
