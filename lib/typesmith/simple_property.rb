# frozen_string_literal: true

module Typesmith
  class SimpleProperty < BaseProperty
    attr_reader :type

    def initialize(name, type, optional: false)
      super(name, optional: optional)
      @type = type
      self.class.validate_type(type)
    end

    def to_typescript
      "#{camelized_name}#{optional_suffix}: #{get_type_string(type)};"
    end

    def process_value(value)
      if type.is_a?(Class) && type < Definition
        type.new(value).attributes
      else
        value
      end
    end
  end
end
