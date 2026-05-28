module ImageStorages
  class ImageStorage
    def store(uploaded_file:, work_order_id:)
      raise NotImplementedError, "#{self.class.name} must implement #store"
    end
  end
end
