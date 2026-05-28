require "test_helper"

module WorkOrders
  class CreateTest < ActiveSupport::TestCase
    FakeStorage = Struct.new(:stored_files, keyword_init: true) do
      def store(uploaded_file:, work_order_id:)
        self.stored_files ||= []
        stored_files << { filename: uploaded_file.original_filename, work_order_id: work_order_id }
        "fake/#{work_order_id}/#{uploaded_file.original_filename}"
      end
    end

    test "creates a work order and persists images through the storage abstraction" do
      image_storage = FakeStorage.new
      uploaded_files = [
        fixture_file_upload("sample-upload.jpg", "image/jpeg"),
        fixture_file_upload("sample-upload.jpg", "image/jpeg")
      ]

      work_order = nil

      assert_difference("WorkOrder.count", 1) do
        assert_difference("Image.count", 2) do
          work_order = Create.call(
            work_order_attributes: {
              license_plate: "ABCD12",
              customer_name: "Jane Doe",
              mileage: 54_321,
              reason_for_entry: "Engine noise",
              priority: "high"
            },
            image_files: uploaded_files,
            image_storage: image_storage
          )
        end
      end

      assert_equal 2, image_storage.stored_files.size
      assert_equal work_order.id, image_storage.stored_files.first[:work_order_id]
      assert_equal ["fake/#{work_order.id}/sample-upload.jpg", "fake/#{work_order.id}/sample-upload.jpg"], work_order.images.order(:id).pluck(:storage_path)
    end

    private

    def fixture_file_upload(...)
      ActionDispatch::TestProcess::FixtureFile.instance_method(:fixture_file_upload).bind_call(self, ...)
    end
  end
end
