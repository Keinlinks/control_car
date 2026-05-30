class WorkOrderAnalysis < EntityRecord
  enum :estimated_priority, { low: 0, high: 1 }

  belongs_to :work_order

  attribute :work_order_snapshot, :json, default: {}
  attribute :possible_failures, :json, default: []
  attribute :recommended_steps, :json, default: []

  validates :estimated_category, presence: true
  validates :estimated_priority, presence: true
  validate :work_order_snapshot_must_be_a_hash
  validate :possible_failures_must_be_an_array_of_strings
  validate :recommended_steps_must_be_an_array_of_strings

  private

  def work_order_snapshot_must_be_a_hash
    return if work_order_snapshot.is_a?(Hash)

    errors.add(:work_order_snapshot, "must be a hash")
  end

  def possible_failures_must_be_an_array_of_strings
    validate_array_of_strings(:possible_failures)
  end

  def recommended_steps_must_be_an_array_of_strings
    validate_array_of_strings(:recommended_steps)
  end

  def validate_array_of_strings(attribute_name)
    value = public_send(attribute_name)

    unless value.is_a?(Array)
      errors.add(attribute_name, "must be an array")
      return
    end

    return if value.all? { |item| item.is_a?(String) }

    errors.add(attribute_name, "must contain only strings")
  end
end
