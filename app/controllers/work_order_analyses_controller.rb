class WorkOrderAnalysesController < ApplicationController
  MAX_PAGE_SIZE = 100

  def index
    work_order = WorkOrder.find(params[:work_order_id])

    validation_error = pagination_validation_error

    if validation_error
      render json: { errors: [validation_error] }, status: :unprocessable_content
      return
    end

    analyses = work_order.work_order_analyses
                         .order(created_at: :desc)
                         .offset((page - 1) * page_size)
                         .limit(page_size)

    render json: {
      items: analyses.map { |analysis| serialize_analysis(analysis) },
      page: page,
      pageSize: page_size,
      total: work_order.work_order_analyses.count
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { errors: ["work_order not found"] }, status: :not_found
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

  def serialize_analysis(analysis)
    {
      id: analysis.id,
      estimated_category: analysis.estimated_category,
      possible_failures: analysis.possible_failures,
      estimated_priority: analysis.estimated_priority,
      recommended_steps: analysis.recommended_steps,
      work_order_id: analysis.work_order_id,
      created_at: analysis.created_at,
      updated_at: analysis.updated_at
    }
  end
end
