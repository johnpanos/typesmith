# frozen_string_literal: true

module Typesmith
  class BaseProperty
    class InvalidTypeError < StandardError; end
    PRIMITIVE_TYPES = %i[string number boolean any null undefined void never unknown object Date].freeze

    attr_reader :name, :optional

    def initialize(name, optional: false)
      @name = name
      @optional = optional
    end

    def to_typescript
      raise NotImplementedError, "Subclasses must implement to_typescript"
    end

    def process_value(value)
      value
    end

    protected

    def optional_suffix
      optional ? "?" : ""
    end

    def camelized_name
      name.to_s.camelize(:lower)
    end

    def get_type_string(type)
      case type
      when Class
        type < Definition ? type.typescript_type_name : type.to_s
      when Array
        "#{get_type_string(type.first)}[]"
      when Hash
        key_type, value_type = type.first
        "{ [key: #{get_type_string(key_type)}]: #{get_type_string(value_type)} }"
      else
        type.to_s
      end
    end

    def self.validate_type(type)
      return if PRIMITIVE_TYPES.include?(type) || type.is_a?(Class) && type < Definition

      case type
      when Array
        validate_type(type.first)
      when Hash
        key_type, value_type = type.first
        validate_type(key_type)
        validate_type(value_type)
      else
        raise InvalidTypeError, "Invalid type: #{type}. Must be a primitive type or a Definition subclass."
      end
    end
  end
end
