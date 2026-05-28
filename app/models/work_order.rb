class WorkOrder < EntityRecord
  enum :priority, { low: 0, high: 1 }

  has_many :images, dependent: :destroy
end
