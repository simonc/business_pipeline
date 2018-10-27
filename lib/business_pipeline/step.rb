# frozen_string_literal: true

require 'business_pipeline/config'
require 'business_pipeline/context'
require 'business_pipeline/hooks'

module BusinessPipeline
  module Step
    def self.included(base)
      base.class_eval do
        include Hooks

        attr_reader :context
        private :context

        attr_reader :config
        private :config

        def self.inherited(child_class)
          child_class.instance_variable_set(:@hooks, hooks)
        end
      end
    end

    def initialize(config = {})
      @config = BusinessPipeline::Config.new(config)
    end

    def call
      fail NotImplementedError
    end

    def fail!(additional_context = {})
      context.fail!(additional_context)
    end

    def perform(context = {})
      @context = BusinessPipeline::Context.build(context)
      with_hooks { call }
      @context
    end

    def succeed!(additional_context = {})
      context.succeed!(additional_context)
    end
  end
end
