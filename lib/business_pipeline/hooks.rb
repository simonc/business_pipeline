# frozen_string_literal: true

module BusinessPipeline
  module Hooks
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def add_hooks(*new_hooks, type: __callee__, &block)
        hooks[type] += [*new_hooks, block].compact.map do |hook|
          hook.respond_to?(:new) ? hook.new : hook
        end
      end
      alias_method :after, :add_hooks
      alias_method :around, :add_hooks
      alias_method :before, :add_hooks

      def hooks
        @hooks ||= { after: [], around: [], before: [] }
      end
    end

    private def run_around_hooks(&block)
      around_hooks = self.class.hooks[:around]

      around_hooks
        .reverse
        .inject(block) { |chain, hook| proc { run_hook(hook, chain) } }
        .call
    end

    private def with_hooks
      run_around_hooks do
        run_hooks :before
        yield
        run_hooks :after
      end
    end

    private def run_hooks(type)
      self.class.hooks[type].each { |hook| run_hook(hook) }
    end

    private def run_hook(hook, *args)
      hook = method(hook) if hook.is_a?(Symbol)
      hook.call(*args, context, config)
    end
  end
end
