class WorkOrderAnalysesController < ApplicationController
  def index
    work_order = WorkOrder.find(params[:work_order_id])

    if page < 1 || page_size < 1
      render json: { errors: ["page and pageSize must be greater than 0"] }, status: :unprocessable_content
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
