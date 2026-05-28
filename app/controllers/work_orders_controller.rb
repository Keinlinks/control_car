class WorkOrdersController < ApplicationController
  MAX_PAGE_SIZE = 100

  def index
    validation_error = pagination_validation_error

    if validation_error
      render json: { errors: [validation_error] }, status: :unprocessable_content
      return
    end

    work_orders = WorkOrder.order(created_at: :desc)
                          .offset((page - 1) * page_size)
                          .limit(page_size)

    render json: {
      items: work_orders.map { |work_order| serialize_work_order_summary(work_order) },
      page: page,
      pageSize: page_size,
      total: WorkOrder.count
    }, status: :ok
  end

  def create
    work_order = WorkOrder.new(work_order_params)
    work_order.validate
    validate_images(work_order)

    if work_order.errors.any?
      render json: { errors: work_order.errors.full_messages }, status: :unprocessable_content
      return
    end

    result = WorkOrders::Create.call(
      work_order_attributes: work_order.attributes.symbolize_keys.except("id", :id, "created_at", :created_at, "updated_at", :updated_at),
      image_files: image_files,
      image_storage: ImageStorages::LocalImageStorage.new,
      ai_service: AiServices::MockAiService.new
    )

    render json: serialize_result(result), status: :created
  end

  private

  def page
    params.fetch(:page, 1).to_i
  end

  def page_size
    params.fetch(:pageSize, 10).to_i
  end

  def pagination_validation_error
    return "page and pageSize must be greater than 0" if page < 1 || page_size < 1
    return "pageSize must be less than or equal to #{MAX_PAGE_SIZE}" if page_size > MAX_PAGE_SIZE

    nil
  end

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

  def serialize_result(result)
    {
      workOrder: serialize_work_order(result.work_order),
      workOrderAnalysis: serialize_work_order_analysis(result.work_order_analysis)
    }
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

  def serialize_work_order_summary(work_order)
    {
      id: work_order.id,
      license_plate: work_order.license_plate,
      customer_name: work_order.customer_name,
      mileage: work_order.mileage,
      reason_for_entry: work_order.reason_for_entry,
      priority: work_order.priority,
      created_at: work_order.created_at,
      updated_at: work_order.updated_at
    }
  end

  def serialize_work_order_analysis(work_order_analysis)
    return nil if work_order_analysis.nil?

    {
      id: work_order_analysis.id,
      estimated_category: work_order_analysis.estimated_category,
      possible_failures: work_order_analysis.possible_failures,
      estimated_priority: work_order_analysis.estimated_priority,
      recommended_steps: work_order_analysis.recommended_steps,
      work_order_id: work_order_analysis.work_order_id
    }
  end
end
