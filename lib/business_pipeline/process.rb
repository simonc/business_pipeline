# frozen_string_literal: true

require 'business_pipeline/config'

module BusinessPipeline
  module Process
    def self.included(base)
      base.class_eval do
        include BusinessPipeline::Step

        extend ClassMethods
        include InstanceMethods
      end
    end

    module InstanceMethods
      def call
        self.class.steps.each do |step_class, block|
          step_config = BusinessPipeline::Config.new(config, &block)
          step = step_class.new(step_config)
          step.perform(context)
        end
      end

      def perform(context = {})
        config._processes ||= []
        config._processes << self

        config._processes.one? ? catch(:early_stop) { super } : super
      ensure
        config._processes.pop
      end
    end

    module ClassMethods
      def step(step_class, &block)
        steps << [step_class, block]
      end

      def steps
        @steps ||= []
      end
    end
  end
end
