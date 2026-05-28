class WorkOrdersController < ApplicationController
  def create
    work_order = WorkOrder.new(work_order_params)
    work_order.validate
    validate_images(work_order)

    if work_order.errors.any?
      render json: { errors: work_order.errors.full_messages }, status: :unprocessable_content
      return
    end

    work_order = WorkOrders::Create.call(
      work_order_attributes: work_order.attributes.symbolize_keys.except("id", :id, "created_at", :created_at, "updated_at", :updated_at),
      image_files: image_files,
      image_storage: ImageStorages::LocalImageStorage.new
    )

    render json: serialize_work_order(work_order), status: :created
  end

  private

  def work_order_params
    params.expect(
      work_order: [
        :license_plate,
        :customer_name,
        :mileage,
        :reason_for_entry,
        :priority
      ]
    )
  end

  def image_files
    Array(params[:images]).compact_blank
  end

  def validate_images(work_order)
    image_files.each do |uploaded_file|
      next if valid_uploaded_file?(uploaded_file)

      work_order.errors.add(:images, "must be uploaded files")
    end
  end

  def valid_uploaded_file?(uploaded_file)
    uploaded_file.respond_to?(:original_filename) && uploaded_file.respond_to?(:read)
  end

  def serialize_work_order(work_order)
    {
      id: work_order.id,
      license_plate: work_order.license_plate,
      customer_name: work_order.customer_name,
      mileage: work_order.mileage,
      reason_for_entry: work_order.reason_for_entry,
      priority: work_order.priority,
      created_at: work_order.created_at,
      updated_at: work_order.updated_at,
      images: work_order.images.map do |image|
        {
          id: image.id,
          storage_path: image.storage_path,
          work_order_id: image.work_order_id,
          created_at: image.created_at,
          updated_at: image.updated_at
        }
      end
    }
  end
end
