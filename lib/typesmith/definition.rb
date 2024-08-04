# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"

module Typesmith
  class Definition
    class Error < StandardError; end
    class UndefinedAttributeError < Error; end

    class << self
      def property(name, type: nil, optional: false, &block)
        properties[name] = case type
                           when Array
                             ArrayProperty.new(name, type.first, optional: optional)
                           when Hash
                             IndexedProperty.new(name, type.keys.first, type.values.first, optional: optional)
                           when nil
                             block ? NestedProperty.new(name, block, optional: optional) : SimpleProperty.new(name, :any, optional: optional)
                           else
                             SimpleProperty.new(name, type, optional: optional)
                           end
      end

      def properties
        @properties ||= {}
      end

      def to_typescript
        generate_typescript_type(name.demodulize, properties)
      end

      def typescript_type_name
        name.demodulize
      end

      private

      def generate_typescript_type(name, props)
        [
          "export interface #{name} {",
          generate_properties(props, 1),
          "}"
        ].join("\n")
      end

      def generate_properties(props, indent_level = 0)
        props.map do |_, prop|
          lines = prop.to_typescript.split("\n")
          lines.map { |line| "  " * indent_level + line }.join("\n")
        end.join("\n")
      end
    end

    attr_reader :attributes

    def properties
      self.class.properties
    end

    def initialize(attributes = {})
      @attributes = {}
      process_attributes(attributes.deep_symbolize_keys)
      validate_required_attributes
    end

    def to_json(*_args)
      @attributes
    end

    def as_json(*_args)
      @attributes
    end

    private

    def process_attributes(attrs)
      undefined_attrs = attrs.keys - properties.keys
      raise UndefinedAttributeError, "Undefined attributes: #{undefined_attrs.join(", ")}" if undefined_attrs.any?

      properties.each do |key, prop|
        if attrs.key?(key)
          @attributes[key] = prop.process_value(attrs[key])
          define_singleton_method(key) { @attributes[key] }
        else
          define_singleton_method(key) { nil }
        end
      end
    end

    def validate_required_attributes
      missing_attrs = properties.reject { |_, v| v.optional }.keys - @attributes.keys
      raise ArgumentError, "Missing required attributes: #{missing_attrs.join(", ")}" if missing_attrs.any?
    end

    def camelize_keys(hash)
      hash.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end
  end
end
