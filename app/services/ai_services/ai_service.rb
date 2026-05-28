module AiServices
  class AiService
    def generate(prompt:, input: nil, options: {})
      raise NotImplementedError, "#{self.class.name} must implement #generate"
    end
  end
end
