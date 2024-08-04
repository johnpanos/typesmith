# frozen_string_literal: true

module Typesmith
  class IndexedProperty < BaseProperty
    attr_reader :key_type, :value_type

    def initialize(name, key_type, value_type, optional: false)
      super(name, optional: optional)
      @key_type = key_type
      @value_type = value_type
      self.class.validate_type(key_type)
      self.class.validate_type(value_type)
    end

    def to_typescript
      "#{camelized_name}#{optional_suffix}: { [key: #{get_type_string(key_type)}]: #{get_type_string(value_type)} };"
    end

    def process_value(value)
      value.transform_values do |v|
        if value_type.is_a?(Array)
          v.map { |item| SimpleProperty.new(nil, value_type.first).process_value(item) }
        else
          SimpleProperty.new(nil, value_type).process_value(v)
        end
      end
    end
  end
end
