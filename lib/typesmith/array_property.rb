# frozen_string_literal: true

module Typesmith
  class ArrayProperty < SimpleProperty
    def to_typescript
      "#{camelized_name}#{optional_suffix}: #{get_type_string(type)}[];"
    end

    def process_value(value)
      value.map { |v| super(v) }
    end
  end
end
