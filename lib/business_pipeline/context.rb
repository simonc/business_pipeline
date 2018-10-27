# frozen_string_literal: true

require 'ostruct'

module BusinessPipeline
  class Context < OpenStruct
    def self.build(context = {})
      context.is_a?(self) ? context : new(context)
    end

    def initialize(*)
      super
      @failure = false
    end

    def fail
      @failure = true
    end

    def fail!(additional_context = {})
      update!(additional_context)
      self.fail
      throw :early_stop, self
    end

    def failure?
      !!@failure
    end

    def succeed!(additional_context = {})
      update!(additional_context)
      throw :early_stop, self
    end

    def success?
      !failure?
    end

    private def update!(context)
      context.each { |key, value| modifiable[key.to_sym] = value }
    end
  end
end
