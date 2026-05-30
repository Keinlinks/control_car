require "test_helper"

module WorkOrders
  class CreateTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    FakeStorage = Struct.new(:stored_files, keyword_init: true) do
      def store(uploaded_file:, work_order_id:)
        self.stored_files ||= []
        stored_files << { filename: uploaded_file.original_filename, work_order_id: work_order_id }
        "fake/#{work_order_id}/#{uploaded_file.original_filename}"
      end

      def delete(storage_path:)
        self.stored_files ||= []
        stored_files << { deleted_path: storage_path }
      end
    end

    FakeAiService = Struct.new(:response, :error, keyword_init: true) do
      def generate(prompt:, input: nil, options: {})
        raise error unless error.nil?

        response
      end
    end

    test "creates a work order and persists images through the storage abstraction" do
      image_storage = FakeStorage.new
      ai_service = FakeAiService.new(
        response: {
          estimated_category: "engine",
          possible_failures: ["Loose timing component"],
          estimated_priority: "high",
          recommended_steps: ["Run engine diagnostics"]
        }
      )
      uploaded_files = [
        fixture_file_upload("sample-upload.jpg", "image/jpeg"),
        fixture_file_upload("sample-upload.jpg", "image/jpeg")
      ]

      result = nil

      assert_difference("WorkOrder.count", 1) do
        assert_difference("Image.count", 2) do
          assert_difference("WorkOrderAnalysis.count", 1) do
            result = Create.call(
              work_order_attributes: {
                license_plate: "ABCD12",
                customer_name: "Jane Doe",
                mileage: 54_321,
                reason_for_entry: "Engine noise",
                priority: "high"
              },
              image_files: uploaded_files,
              image_storage: image_storage,
              ai_service: ai_service
            )
          end
        end
      end

      work_order = result.work_order

      assert_equal 2, image_storage.stored_files.size
      assert_equal work_order.id, image_storage.stored_files.first[:work_order_id]
      assert_equal ["fake/#{work_order.id}/sample-upload.jpg", "fake/#{work_order.id}/sample-upload.jpg"], work_order.images.order(:id).pluck(:storage_path)
      assert_equal "engine", result.work_order_analysis.estimated_category
      assert_equal(
        {
          "license_plate" => "ABCD12",
          "customer_name" => "Jane Doe",
          "mileage" => 54_321,
          "reason_for_entry" => "Engine noise",
          "priority" => "high"
        },
        result.work_order_analysis.reload.work_order_snapshot
      )
    end

    test "continues without analysis when ai fails" do
      result = nil

      assert_difference("WorkOrder.count", 1) do
        assert_no_difference("WorkOrderAnalysis.count") do
          result = Create.call(
            work_order_attributes: {
              license_plate: "ZXCV98",
              customer_name: "John Doe",
              mileage: 12_345,
              reason_for_entry: "Brake check",
              priority: "low"
            },
            image_files: [],
            image_storage: FakeStorage.new,
            ai_service: FakeAiService.new(error: StandardError.new("AI failure"))
          )
        end
      end

      assert_not_nil result.work_order
      assert_nil result.work_order_analysis
    end

    test "enqueues orphaned images cleanup when persistence fails after upload" do
      failing_create_class = Class.new(Create) do
        private

        def persist_images!(work_order)
          super
          raise StandardError, "failure after upload"
        end
      end

      image_storage = FakeStorage.new

      clear_enqueued_jobs

      assert_raises(StandardError) do
        failing_create_class.call(
          work_order_attributes: {
            license_plate: "QWER12",
            customer_name: "Mary Doe",
            mileage: 7_000,
            reason_for_entry: "Inspection",
            priority: "low"
          },
          image_files: [fixture_file_upload("sample-upload.jpg", "image/jpeg")],
          image_storage: image_storage,
          ai_service: FakeAiService.new(response: {})
        )
      end

      assert_equal 1, enqueued_jobs.size
      assert_equal DeleteOrphanedImagesJob, enqueued_jobs.first[:job]
      assert_equal image_storage.class.name, enqueued_jobs.first[:args][0]
      assert_equal ["fake/1/sample-upload.jpg"], enqueued_jobs.first[:args][1]
    end

    private

    def fixture_file_upload(...)
      ActionDispatch::TestProcess::FixtureFile.instance_method(:fixture_file_upload).bind_call(self, ...)
    end
  end
end
