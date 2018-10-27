# frozen_string_literal: true

require 'ostruct'

module BusinessPipeline
  class Config < OpenStruct
    def initialize(hash = nil, &block)
      super(hash)
      instance_eval(&block) if block
    end

    def fetch(key)
      value = self[key.to_sym]

      return value unless value.nil?
      return yield(key) if block_given?

      fail KeyError, key
    end

    # rubocop:disable Style/MissingRespondToMissing
    def method_missing(meth, *args, &block)
      if args.size.zero? || meth.to_s.end_with?('=')
        super
      else
        self[meth] = args.first
      end
    end
    # rubocop:enable Style/MissingRespondToMissing

    attr_reader :data
    private :data
  end
end
