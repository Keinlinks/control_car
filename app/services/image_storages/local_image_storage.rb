require "fileutils"
require "securerandom"

module ImageStorages
  class LocalImageStorage < ImageStorage
    def store(uploaded_file:, work_order_id:)
      relative_path = build_storage_path(work_order_id, uploaded_file)
      absolute_path = Rails.root.join("storage", relative_path)

      FileUtils.mkdir_p(absolute_path.dirname)
      File.binwrite(absolute_path, uploaded_file.read)

      relative_path.to_s
    end

    def delete(storage_path:)
      absolute_path = Rails.root.join("storage", storage_path)

      File.delete(absolute_path) if File.exist?(absolute_path)
    end

    private

    def build_storage_path(work_order_id, uploaded_file)
      extension = File.extname(uploaded_file.original_filename.to_s)
      filename = "#{SecureRandom.uuid}#{extension}"

      Pathname.new("work_orders").join(work_order_id.to_s, filename)
    end
  end
end
