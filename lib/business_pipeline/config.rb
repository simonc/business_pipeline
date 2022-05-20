# frozen_string_literal: true

require 'ostruct'

module BusinessPipeline
  class Config
    def initialize(hash = nil, &block)
      @data = OpenStruct.new(hash)

      instance_eval(&block) if block
    end

    def fetch(key)
      value = data[key.to_sym]

      return value unless value.nil?
      return yield(key) if block_given?

      fail KeyError, key
    end

    def method_missing(meth, *args, &block)
      if args.size.zero? || meth.to_s.end_with?('=')
        data.public_send(meth, *args, &block)
      else
        data[meth] = args.first
      end
    end

    def respond_to_missing?(meth, include_private = false)
      data.respond_to?(meth, include_private) || super
    end

    attr_reader :data
    private :data
  end
end
