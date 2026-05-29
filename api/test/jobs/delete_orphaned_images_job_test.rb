require "test_helper"

class DeleteOrphanedImagesJobTest < ActiveJob::TestCase
  test "deletes orphaned images using the configured storage implementation" do
    relative_path = "work_orders/test/orphaned-image.jpg"
    absolute_path = Rails.root.join("storage", relative_path)

    FileUtils.mkdir_p(absolute_path.dirname)
    File.binwrite(absolute_path, "orphaned image")

    assert File.exist?(absolute_path)

    DeleteOrphanedImagesJob.perform_now("ImageStorages::LocalImageStorage", [relative_path])

    assert_not File.exist?(absolute_path)
  end
end
