class Image < EntityRecord
  belongs_to :work_order

  validates :storage_path, presence: true
end
