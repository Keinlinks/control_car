class WorkOrder < EntityRecord
  enum :priority, { low: 0, high: 1 }

  has_many :images, dependent: :destroy
  has_one :work_order_analysis, dependent: :destroy

  validates :license_plate, presence: true
  validates :customer_name, presence: true
  validates :mileage, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :reason_for_entry, presence: true
  validates :priority, presence: true
end
