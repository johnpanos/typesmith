# frozen_string_literal: true

module Typesmith
  class NestedProperty < BaseProperty
    attr_reader :block

    def initialize(name, block, optional: false)
      super(name, optional: optional)
      @block = block
    end

    def to_typescript
      nested_class = Class.new(Definition)
      nested_class.class_eval(&block)
      [
        "#{camelized_name}#{optional_suffix}: {",
        nested_class.send(:generate_properties, nested_class.properties).split("\n").map do |line|
          "  #{line}"
        end.join("\n"),
        "};"
      ].join("\n")
    end

    def process_value(value)
      nested_class = Class.new(Definition)
      nested_class.class_eval(&block)
      nested_class.new(value).attributes
    end
  end
end
