class DeleteOrphanedImagesJob < ApplicationJob
  queue_as :default

  def perform(storage_class_name, storage_paths)
    image_storage = storage_class_name.constantize.new

    Array(storage_paths).each do |storage_path|
      image_storage.delete(storage_path:)
    rescue StandardError
      next
    end
  end
end
